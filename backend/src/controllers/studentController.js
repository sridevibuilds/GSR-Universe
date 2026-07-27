// Module 4 Student Mappings & Transactions - Student Controller

const db = require("../config/db");
const Joi = require("joi");

// Input Validation Schema using Joi
const studentCreateSchema = Joi.object({
    admission_no: Joi.string().trim().max(50).required(),
    student_name: Joi.string().trim().max(100).required(),
    class_name: Joi.string().trim().max(20).required(),
    section: Joi.string().trim().max(10).required(),
    primary_parent_name: Joi.string().trim().max(100).required(),
    secondary_parent_name: Joi.string().trim().max(100).allow("", null),
    primary_parent_mobile: Joi.string().trim().pattern(/^[0-9]{10,15}$/).required(),
    secondary_parent_mobile: Joi.string().trim().pattern(/^[0-9]{10,15}$/).allow("", null),
    parent_email: Joi.string().trim().email().max(100).allow("", null),
    date_of_birth: Joi.date().iso().allow(null),
    total_fee: Joi.number().min(0).default(0),
    bus_number: Joi.string().trim().max(50).allow("", null),
    route_name: Joi.string().trim().max(100).allow("", null),
    pickup_point: Joi.string().trim().max(100).allow("", null),
    driver_mobile: Joi.string().trim().pattern(/^[0-9]{10,15}$/).allow("", null)
});

const studentUpdateSchema = Joi.object({
    student_name: Joi.string().trim().max(100).required(),
    class_name: Joi.string().trim().max(20).required(),
    section: Joi.string().trim().max(10).required(),
    primary_parent_name: Joi.string().trim().max(100).required(),
    secondary_parent_name: Joi.string().trim().max(100).allow("", null),
    primary_parent_mobile: Joi.string().trim().pattern(/^[0-9]{10,15}$/).required(),
    secondary_parent_mobile: Joi.string().trim().pattern(/^[0-9]{10,15}$/).allow("", null),
    parent_email: Joi.string().trim().email().max(100).allow("", null),
    date_of_birth: Joi.date().iso().allow(null),
    bus_number: Joi.string().trim().max(50).allow("", null),
    route_name: Joi.string().trim().max(100).allow("", null),
    pickup_point: Joi.string().trim().max(100).allow("", null),
    driver_mobile: Joi.string().trim().pattern(/^[0-9]{10,15}$/).allow("", null)
});

// ==========================================
// CREATE STUDENT (Transaction-safe)
// ==========================================
const createStudent = async (req, res, next) => {
    // Start transactional client from pool
    const client = await db.connect();

    try {
        // Validate input payload
        const { error, value } = studentCreateSchema.validate(req.body, { stripUnknown: true });
        if (error) {
            return res.status(400).json({
                success: false,
                message: `Validation Error: ${error.details.map(d => d.message).join(", ")}`
            });
        }

        const {
            admission_no,
            student_name,
            class_name,
            section,
            primary_parent_name,
            secondary_parent_name,
            primary_parent_mobile,
            secondary_parent_mobile,
            parent_email,
            date_of_birth,
            total_fee,
            bus_number,
            route_name,
            pickup_point,
            driver_mobile
        } = value;

        // Check if admission number is already taken
        const existing = await client.query(
            "SELECT id FROM public.students WHERE admission_no = $1",
            [admission_no]
        );

        if (existing.rows.length > 0) {
            return res.status(400).json({
                success: false,
                message: "Admission Number already exists."
            });
        }

        // Fetch current active academic year
        const ayResult = await client.query(
            "SELECT id, year_name FROM public.academic_years WHERE is_current = true LIMIT 1"
        );

        if (ayResult.rows.length === 0) {
            return res.status(400).json({
                success: false,
                message: "No current active academic year is configured. Configure it in database first."
            });
        }

        const academicYear = ayResult.rows[0];

        // Retrieve or dynamically setup the class inside classes table to ensure mapping target exists
        let classResult = await client.query(
            "SELECT id FROM public.classes WHERE class_name = $1 AND section = $2 AND academic_year = $3",
            [class_name, section, academicYear.year_name]
        );

        let classId;
        if (classResult.rows.length === 0) {
            // Auto-create class if it doesn't exist to make initialization seamless
            const newClass = await client.query(
                `INSERT INTO public.classes (class_name, section, academic_year) 
                 VALUES ($1, $2, $3) RETURNING id`,
                [class_name, section, academicYear.year_name]
            );
            classId = newClass.rows[0].id;
        } else {
            classId = classResult.rows[0].id;
        }

        // BEGIN TRANSACTION
        await client.query("BEGIN");

        // 1. Insert Student Record
        const studentInsert = await client.query(
            `INSERT INTO public.students
            (
                admission_no, student_name, class_name, section,
                primary_parent_name, secondary_parent_name,
                primary_parent_mobile, secondary_parent_mobile,
                parent_email, date_of_birth
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            RETURNING *`,
            [
                admission_no, student_name, class_name, section,
                primary_parent_name, secondary_parent_name,
                primary_parent_mobile, secondary_parent_mobile,
                parent_email, date_of_birth
            ]
        );

        const student = studentInsert.rows[0];

        // 2. Generate Roll Number (Auto-increment within that class/section)
        const rollResult = await client.query(
            `SELECT COALESCE(MAX(class_roll_number), 0) + 1 AS next_roll 
             FROM public.student_class_mapping 
             WHERE class_id = $1 AND academic_year_id = $2`,
            [classId, academicYear.id]
        );
        const nextRoll = rollResult.rows[0].next_roll;

        // 3. Create active Student-Class Mapping record
        const mappingInsert = await client.query(
            `INSERT INTO public.student_class_mapping
            (
                student_id, class_id, academic_year_id, 
                class_roll_number, is_current, joined_on
            )
            VALUES ($1, $2, $3, $4, true, CURRENT_DATE)
            RETURNING id`,
            [student.id, classId, academicYear.id, nextRoll]
        );

        const mappingId = mappingInsert.rows[0].id;

        // 4. Initialize Fees Ledger Record
        // Set faculty ID to current user ID or fallback to first faculty if admin creates
        const staffId = req.user.role === "FACULTY" ? req.user.id : 1; 

        await client.query(
            `INSERT INTO public.fees
            (
                student_class_mapping_id, academic_year_id,
                total_fee, paid_amount, pending_amount, 
                due_date, updated_by, remarks
            )
            VALUES ($1, $2, $3, 0, $3, CURRENT_DATE + INTERVAL '30 days', $4, 'Initial term setup fee.')`,
            [mappingId, academicYear.id, total_fee, staffId]
        );

        // 5. Initialize Transport Record if details provided
        if (bus_number && bus_number.trim() !== "") {
            await client.query(
                `INSERT INTO public.transport
                (
                    student_class_mapping_id, bus_number, route_name, pickup_point,
                    driver_name, driver_mobile, attendant_name, attendant_mobile, updated_by
                )
                VALUES ($1, $2, $3, $4, 'Ram Singh', $5, 'Shanti Devi', '9876543211', $6)`,
                [mappingId, bus_number, route_name || 'School Route', pickup_point || 'Main Stop', driver_mobile || '9876543210', staffId]
            );
        }

        // COMMIT TRANSACTION
        await client.query("COMMIT");

        res.status(201).json({
            success: true,
            message: "Student Created and Class Mapped Successfully",
            student: {
                ...student,
                student_class_mapping_id: mappingId,
                class_roll_number: nextRoll,
                class_id: classId,
                academic_year_id: academicYear.id
            }
        });

    } catch (err) {
        // ROLLBACK ON FAILURE
        await client.query("ROLLBACK");
        next(err);
    } finally {
        // Release client back to the pool
        client.release();
    }
};

// ==========================================
// GET ALL STUDENTS (Optimized with Mappings)
// ==========================================
const getAllStudents = async (req, res, next) => {
    try {
        const result = await db.query(
            `SELECT s.*, 
                    scm.id as student_class_mapping_id, 
                    scm.class_roll_number, 
                    scm.is_current,
                    c.id as class_id, 
                    ay.id as academic_year_id, 
                    ay.year_name as academic_year,
                    COALESCE((SELECT (COUNT(CASE WHEN att.status = 'Present' THEN 1 END) * 100.0) / NULLIF(COUNT(att.id), 0) FROM public.attendance att WHERE att.student_class_mapping_id = scm.id), 100.0) as attendance_percentage,
                    f.total_fee, f.paid_amount, f.pending_amount,
                    t.bus_number, t.route_name, t.pickup_point, t.driver_mobile
             FROM public.students s
             LEFT JOIN public.student_class_mapping scm 
                ON s.id = scm.student_id AND scm.is_current = true
             LEFT JOIN public.classes c 
                ON scm.class_id = c.id
             LEFT JOIN public.academic_years ay 
                ON scm.academic_year_id = ay.id
             LEFT JOIN public.fees f
                ON f.student_class_mapping_id = scm.id
             LEFT JOIN public.transport t
                ON t.student_class_mapping_id = scm.id
             ORDER BY s.student_name`
        );

        res.json({
            success: true,
            total: result.rows.length,
            students: result.rows
        });
    } catch (err) {
        next(err);
    }
};

// ==========================================
// GET STUDENT BY ID
// ==========================================
const getStudentById = async (req, res, next) => {
    try {
        const result = await db.query(
            `SELECT s.*, 
                    scm.id as student_class_mapping_id, 
                    scm.class_roll_number, 
                    scm.is_current,
                    c.id as class_id, 
                    ay.id as academic_year_id, 
                    ay.year_name as academic_year
             FROM public.students s
             LEFT JOIN public.student_class_mapping scm 
                ON s.id = scm.student_id AND scm.is_current = true
             LEFT JOIN public.classes c 
                ON scm.class_id = c.id
             LEFT JOIN public.academic_years ay 
                ON scm.academic_year_id = ay.id
             WHERE s.id = $1`,
            [req.params.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Student Not Found"
            });
        }

        res.json({
            success: true,
            student: result.rows[0]
        });
    } catch (err) {
        next(err);
    }
};

// ==========================================
// UPDATE STUDENT (Auto sync class mappings)
// ==========================================
const updateStudent = async (req, res, next) => {
    const client = await db.connect();

    try {
        const id = req.params.id;

        // Validate payload
        const { error, value } = studentUpdateSchema.validate(req.body, { stripUnknown: true });
        if (error) {
            return res.status(400).json({
                success: false,
                message: `Validation Error: ${error.details.map(d => d.message).join(", ")}`
            });
        }

        const {
            student_name,
            class_name,
            section,
            primary_parent_name,
            secondary_parent_name,
            primary_parent_mobile,
            secondary_parent_mobile,
            parent_email,
            date_of_birth,
            bus_number,
            route_name,
            pickup_point,
            driver_mobile
        } = value;

        // Check if student exists
        const checkResult = await client.query(
            "SELECT id FROM public.students WHERE id = $1",
            [id]
        );

        if (checkResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Student Not Found"
            });
        }

        await client.query("BEGIN");

        // Update raw student details
        const studentUpdate = await client.query(
            `UPDATE public.students
            SET
                student_name = $1,
                class_name = $2,
                section = $3,
                primary_parent_name = $4,
                secondary_parent_name = $5,
                primary_parent_mobile = $6,
                secondary_parent_mobile = $7,
                parent_email = $8,
                date_of_birth = $9
            WHERE id = $10
            RETURNING *`,
            [
                student_name, class_name, section,
                primary_parent_name, secondary_parent_name,
                primary_parent_mobile, secondary_parent_mobile,
                parent_email, date_of_birth,
                id
            ]
        );

        // Fetch current active academic year ID
        const ayResult = await client.query(
            "SELECT id, year_name FROM public.academic_years WHERE is_current = true LIMIT 1"
        );

        if (ayResult.rows.length > 0) {
            const academicYear = ayResult.rows[0];

            // Resolve target class ID
            let classResult = await client.query(
                "SELECT id FROM public.classes WHERE class_name = $1 AND section = $2 AND academic_year = $3",
                [class_name, section, academicYear.year_name]
            );

            let classId;
            if (classResult.rows.length === 0) {
                const newClass = await client.query(
                    `INSERT INTO public.classes (class_name, section, academic_year) 
                     VALUES ($1, $2, $3) RETURNING id`,
                    [class_name, section, academicYear.year_name]
                );
                classId = newClass.rows[0].id;
            } else {
                classId = classResult.rows[0].id;
            }

            // Update class mapping if it exists, or create if missing
            const mapResult = await client.query(
                "SELECT id, class_id FROM public.student_class_mapping WHERE student_id = $1 AND is_current = true",
                [id]
            );

            if (mapResult.rows.length > 0) {
                const currentMap = mapResult.rows[0];
                if (currentMap.class_id !== classId) {
                    // Update mapping to point to the new class
                    await client.query(
                        `UPDATE public.student_class_mapping 
                         SET class_id = $1 
                         WHERE id = $2`,
                        [classId, currentMap.id]
                    );
                }
            } else {
                // If mapping doesn't exist, create it
                const rollResult = await client.query(
                    `SELECT COALESCE(MAX(class_roll_number), 0) + 1 AS next_roll 
                     FROM public.student_class_mapping 
                     WHERE class_id = $1 AND academic_year_id = $2`,
                    [classId, academicYear.id]
                );
                const nextRoll = rollResult.rows[0].next_roll;

                await client.query(
                    `INSERT INTO public.student_class_mapping
                    (student_id, class_id, academic_year_id, class_roll_number, is_current, joined_on)
                    VALUES ($1, $2, $3, $4, true, CURRENT_DATE)`,
                    [id, classId, academicYear.id, nextRoll]
                );
            }
            // Resolve active mapping ID again (or create mapping if needed)
            const finalMap = await client.query(
                "SELECT id FROM public.student_class_mapping WHERE student_id = $1 AND is_current = true",
                [id]
            );
            if (finalMap.rows.length > 0) {
                const mappingId = finalMap.rows[0].id;
                const staffId = req.user.role === "FACULTY" ? req.user.id : 1; 

                const transportCheck = await client.query(
                    "SELECT id FROM public.transport WHERE student_class_mapping_id = $1",
                    [mappingId]
                );

                if (bus_number && bus_number.trim() !== "") {
                    if (transportCheck.rows.length > 0) {
                        await client.query(
                            `UPDATE public.transport 
                             SET bus_number = $1, route_name = $2, pickup_point = $3, driver_mobile = $4, updated_by = $5, updated_at = CURRENT_TIMESTAMP
                             WHERE student_class_mapping_id = $6`,
                            [bus_number, route_name || 'School Route', pickup_point || 'Main Stop', driver_mobile || '9876543210', staffId, mappingId]
                        );
                    } else {
                        await client.query(
                            `INSERT INTO public.transport
                            (
                                student_class_mapping_id, bus_number, route_name, pickup_point,
                                driver_name, driver_mobile, attendant_name, attendant_mobile, updated_by
                            )
                            VALUES ($1, $2, $3, $4, 'Ram Singh', $5, 'Shanti Devi', '9876543211', $6)`,
                            [mappingId, bus_number, route_name || 'School Route', pickup_point || 'Main Stop', driver_mobile || '9876543210', staffId]
                        );
                    }
                } else {
                    // Delete transport mapping if it is empty/unchecked
                    await client.query("DELETE FROM public.transport WHERE student_class_mapping_id = $1", [mappingId]);
                }
            }
        }

        await client.query("COMMIT");

        res.json({
            success: true,
            message: "Student Updated Successfully",
            student: studentUpdate.rows[0]
        });

    } catch (err) {
        await client.query("ROLLBACK");
        next(err);
    } finally {
        client.release();
    }
};

// ==========================================
// DELETE STUDENT
// ==========================================
const deleteStudent = async (req, res, next) => {
    try {
        const result = await db.query(
            "DELETE FROM public.students WHERE id = $1 RETURNING *",
            [req.params.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Student Not Found"
            });
        }

        res.json({
            success: true,
            message: "Student Deleted Successfully"
        });
    } catch (err) {
        next(err);
    }
};

// ==========================================
// PROMOTE STUDENTS (Transaction-safe)
// ==========================================
const promoteStudentsSchema = Joi.object({
    current_academic_year_id: Joi.number().integer().required(),
    destination_academic_year_id: Joi.number().integer().required(),
    current_class_id: Joi.number().integer().required(),
    destination_class_id: Joi.number().integer().optional().allow(null),
    destination_class_name: Joi.string().optional().allow(''),
    destination_section: Joi.string().optional().allow(''),
    student_ids: Joi.array().items(Joi.number().integer()).min(1).required(),
    new_fee_amount: Joi.number().min(0).default(0)
});

const promoteStudents = async (req, res, next) => {
    const client = await db.connect();

    try {
        const { error, value } = promoteStudentsSchema.validate(req.body, { stripUnknown: true });
        if (error) {
            return res.status(400).json({
                success: false,
                message: `Validation Error: ${error.details.map(d => d.message).join(", ")}`
            });
        }

        let {
            current_academic_year_id,
            destination_academic_year_id,
            current_class_id,
            destination_class_id,
            destination_class_name,
            destination_section,
            student_ids,
            new_fee_amount
        } = value;

        // Resolve destination_class_id if class_name and section are passed
        if (!destination_class_id && destination_class_name) {
            const cleanClassName = destination_class_name.trim();
            const cleanSection = (destination_section || 'A').trim();
            let destClassRes = await client.query(
                "SELECT id FROM public.classes WHERE (class_name = $1 OR class_name = $2) AND section = $3 LIMIT 1",
                [cleanClassName, cleanClassName.replace("Class ", "") + "th", cleanSection]
            );
            if (destClassRes.rows.length > 0) {
                destination_class_id = destClassRes.rows[0].id;
            } else {
                const insertClass = await client.query(
                    "INSERT INTO public.classes (class_name, section, academic_year) VALUES ($1, $2, (SELECT year_name FROM public.academic_years WHERE id = $3)) RETURNING id",
                    [cleanClassName, cleanSection, destination_academic_year_id]
                );
                destination_class_id = insertClass.rows[0].id;
            }
        }

        if (!destination_class_id) {
            throw new Error("destination_class_id or destination_class_name must be provided.");
        }

        const staffId = req.user.id;

        await client.query("BEGIN");

        const promotedStudents = [];

        for (const studentId of student_ids) {
            // 1. Get current active mapping for the student
            let currentMapQuery = await client.query(
                `SELECT id FROM public.student_class_mapping 
                 WHERE student_id = $1 AND is_current = true LIMIT 1`,
                [studentId]
            );

            if (currentMapQuery.rows.length === 0) {
                currentMapQuery = await client.query(
                    `SELECT id FROM public.student_class_mapping 
                     WHERE student_id = $1 ORDER BY id DESC LIMIT 1`,
                    [studentId]
                );
            }

            if (currentMapQuery.rows.length === 0) {
                throw new Error(`Student ID ${studentId} does not have any mapping record.`);
            }

            const currentScmId = currentMapQuery.rows[0].id;

            // 2. Mark current mapping as old (is_current = false, promoted details)
            await client.query(
                `UPDATE public.student_class_mapping 
                 SET is_current = false, promoted_by = $1, promoted_on = CURRENT_TIMESTAMP 
                 WHERE id = $2`,
                [staffId, currentScmId]
            );

            // 3. Calculate next roll number in destination class
            const rollResult = await client.query(
                `SELECT COALESCE(MAX(class_roll_number), 0) + 1 AS next_roll 
                 FROM public.student_class_mapping 
                 WHERE class_id = $1 AND academic_year_id = $2`,
                [destination_class_id, destination_academic_year_id]
            );
            const nextRoll = rollResult.rows[0].next_roll;

            // 4. Create new mapping in destination class
            const newMapInsert = await client.query(
                `INSERT INTO public.student_class_mapping
                 (student_id, class_id, academic_year_id, class_roll_number, is_current, joined_on)
                 VALUES ($1, $2, $3, $4, true, CURRENT_DATE)
                 RETURNING id`,
                [studentId, destination_class_id, destination_academic_year_id, nextRoll]
            );
            const newScmId = newMapInsert.rows[0].id;

            // 5. Query old dues from current fees record
            const feeQuery = await client.query(
                "SELECT pending_amount FROM public.fees WHERE student_class_mapping_id = $1",
                [currentScmId]
            );

            let oldDues = 0;
            if (feeQuery.rows.length > 0) {
                oldDues = parseFloat(feeQuery.rows[0].pending_amount) || 0;
            }

            // 6. Create new fee record for the destination academic year
            await client.query(
                `INSERT INTO public.fees
                 (
                     student_class_mapping_id, academic_year_id, total_fee, 
                     paid_amount, pending_amount, due_date, updated_by, remarks
                 )
                 VALUES ($1, $2, $3, 0, $3, CURRENT_DATE + INTERVAL '30 days', $4, $5)`,
                [
                    newScmId,
                    destination_academic_year_id,
                    new_fee_amount,
                    staffId,
                    `Promoted. Prev outstanding dues carried over: $${oldDues}.`
                ]
            );

            // 6b. Carry forward transport mapping if active
            const transportQuery = await client.query(
                `SELECT * FROM public.transport WHERE student_class_mapping_id = $1 LIMIT 1`,
                [currentScmId]
            );
            if (transportQuery.rows.length > 0) {
                const tr = transportQuery.rows[0];
                await client.query(
                    `INSERT INTO public.transport
                     (
                         student_class_mapping_id, bus_number, route_name, pickup_point, 
                         drop_point, driver_name, driver_mobile, attendant_name, 
                         attendant_mobile, remarks, updated_by
                     )
                     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
                    [
                        newScmId,
                        tr.bus_number,
                        tr.route_name,
                        tr.pickup_point,
                        tr.drop_point,
                        tr.driver_name,
                        tr.driver_mobile,
                        tr.attendant_name,
                        tr.attendant_mobile,
                        tr.remarks,
                        staffId
                    ]
                );
            }

            promotedStudents.push({ studentId, newRoll: nextRoll });
        }

        await client.query("COMMIT");

        res.status(200).json({
            success: true,
            message: `Successfully promoted ${student_ids.length} students.`,
            data: promotedStudents
        });

    } catch (error) {
        await client.query("ROLLBACK");
        next(error);
    } finally {
        client.release();
    }
};

const createAcademicYear = async (req, res, next) => {
    try {
        const { year_name } = req.body;
        if (!year_name) {
            return res.status(400).json({ success: false, message: "year_name is required" });
        }

        // Insert new year
        const result = await db.query(
            `INSERT INTO public.academic_years (year_name, is_current, start_date, end_date)
             VALUES ($1, false, $2 || '-06-01', $3 || '-04-30') RETURNING id`,
            [year_name, year_name.split('-')[0], year_name.split('-')[1]]
        );
        const newYearId = result.rows[0].id;

        // Copy classes from the current year to the new year
        const currentYearRes = await db.query("SELECT year_name FROM public.academic_years WHERE is_current = true LIMIT 1");
        if (currentYearRes.rows.length > 0) {
            const currentYearName = currentYearRes.rows[0].year_name;
            const classesRes = await db.query("SELECT DISTINCT class_name, section FROM public.classes WHERE academic_year = $1", [currentYearName]);
            for (const cls of classesRes.rows) {
                await db.query(
                    "INSERT INTO public.classes (class_name, section, academic_year) VALUES ($1, $2, $3)",
                    [cls.class_name, cls.section, year_name]
                );
            }
        }

        res.status(201).json({
            success: true,
            message: `Academic year ${year_name} created and classes copied successfully.`,
            data: { id: newYearId, year_name }
        });
    } catch (err) {
        next(err);
    }
};

module.exports = {
    createStudent,
    getAllStudents,
    getStudentById,
    updateStudent,
    deleteStudent,
    promoteStudents,
    createAcademicYear
};