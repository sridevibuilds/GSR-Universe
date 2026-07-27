// GSR Universe Backend Complete Verification Suite
const { Pool } = require("pg");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");
require("dotenv").config();

const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD
});

const API_BASE = `http://127.0.0.1:${process.env.PORT || 5000}`;

async function runTests() {
    console.log("==================================================");
    console.log("🚀 STARTING BACKEND INTEGRATION & DATABASE VERIFICATION");
    console.log("==================================================");

    const report = {
        dbTables: false,
        dbIndexes: false,
        dbTriggers: false,
        parentOtpSend: false,
        parentOtpVerify: false,
        parentSwitchChild: false,
        studentCreateTransaction: false,
        attendanceScanBarcode: false,
        studentPromotion: false,
        facultyForgotPassword: false
    };

    try {
        // --------------------------------------------------
        // TEST 1: DATABASE SCHEMA VERIFICATION
        // --------------------------------------------------
        console.log("\n[TEST 1] Verifying Database Schema...");
        
        // Check new tables exist
        const tablesRes = await pool.query(`
            SELECT table_name FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name IN ('otps', 'fcm_tokens', 'call_settings', 'call_history')
        `);
        const foundTables = tablesRes.rows.map(r => r.table_name);
        console.log("   - Found Tables:", foundTables);
        if (foundTables.length === 4) {
            report.dbTables = true;
            console.log("   ✅ Support tables exist.");
        } else {
            console.log("   ❌ Missing support tables.");
        }

        // Check indexes
        const idxRes = await pool.query(`
            SELECT indexname FROM pg_indexes 
            WHERE schemaname = 'public' AND indexname IN ('idx_scm_student', 'idx_attendance_mapping', 'idx_fees_mapping')
        `);
        const foundIndexes = idxRes.rows.map(r => r.indexname);
        console.log("   - Found Indexes:", foundIndexes);
        if (foundIndexes.length === 3) {
            report.dbIndexes = true;
            console.log("   ✅ Database indexes verified.");
        } else {
            console.log("   ❌ Missing optimal database indexes.");
        }

        // Check trigger
        const triggerRes = await pool.query(`
            SELECT trigger_name FROM information_schema.triggers 
            WHERE trigger_schema = 'public' AND trigger_name = 'trigger_sync_student_class'
        `);
        if (triggerRes.rows.length > 0) {
            report.dbTriggers = true;
            console.log("   ✅ Student class synchronization trigger verified.");
        } else {
            console.log("   ❌ Missing sync trigger.");
        }


        // --------------------------------------------------
        // TEST 2: AUTHENTICATION & OTP LIFECYCLE (Parent flow)
        // --------------------------------------------------
        console.log("\n[TEST 2] Verifying Parent Login & OTP lifecycle...");

        // Ensure there is at least one active academic year
        let ayId = 1;
        const ayCheck = await pool.query("SELECT id FROM public.academic_years WHERE is_current = true LIMIT 1");
        if (ayCheck.rows.length === 0) {
            console.log("   - Seeding a current active academic year for testing...");
            const insertAy = await pool.query(`
                INSERT INTO public.academic_years (id, year_name, start_date, end_date, is_current)
                VALUES (1, '2026-2027', '2026-06-01', '2027-04-30', true)
                ON CONFLICT (id) DO UPDATE SET is_current = true
                RETURNING id
            `);
            ayId = insertAy.rows[0].id;
        } else {
            ayId = ayCheck.rows[0].id;
        }

        // Ensure there is a student to link to
        const testMobile = "9988776655";
        await pool.query("DELETE FROM public.students WHERE admission_no = 'TESTBARCODE'");
        const testStudent = await pool.query(`
            INSERT INTO public.students (admission_no, student_name, class_name, section, primary_parent_name, primary_parent_mobile)
            VALUES ('TESTBARCODE', 'Test Student Verification', '10th', 'A', 'Parent Test', $1)
            RETURNING id
        `, [testMobile]);
        
        // Send OTP via API
        const sendOtpRes = await fetch(`${API_BASE}/api/auth/parent/send-otp`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ mobile: testMobile })
        });
        const sendOtpData = await sendOtpRes.json();
        
        if (sendOtpData.success) {
            report.parentOtpSend = true;
            console.log("   ✅ Parent OTP sent API call successful.");
        } else {
            console.log("   ❌ Parent OTP send failed:", sendOtpData);
        }

        // Verify OTP by pulling OTP code from database
        const otpQuery = await pool.query("SELECT otp_hash FROM public.otps WHERE mobile = $1 AND is_verified = false", [testMobile]);
        if (otpQuery.rows.length > 0) {
            // Find what the OTP value is. Since we hash it with SHA-256, we can bypass OTP check by marking it verified directly, 
            // or we mock the verification. But let's check: our verification method actually checks verification in the DB.
            // Since we want to check the verify API endpoint, let's look at the generated OTP.
            // Wait, we printed it to console or we can just fetch the raw unhashed otp if we stored it? No, we store only the hash.
            // To test the verify API, we can insert a known hash in the database!
            // Let's insert a known OTP "555555" and its SHA-256 hash.
            // SHA-256 for "555555" is "c9ec5c3e7d69780003058a9d186c31bf042b32252c8b09340798e6a188be23c2" (actually: crypto hash of '555555')
            const crypto = require("crypto");
            const hash = crypto.createHash("sha256").update("555555").digest("hex");
            
            await pool.query(
                "UPDATE public.otps SET otp_hash = $1, expires_at = NOW() + INTERVAL '5 minutes' WHERE mobile = $2",
                [hash, testMobile]
            );

            // Call verify API
            const verifyRes = await fetch(`${API_BASE}/api/auth/parent/verify-otp`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ mobile: testMobile, otp: "555555" })
            });
            const verifyData = await verifyRes.json();
            
            if (verifyData.success && verifyData.token) {
                report.parentOtpVerify = true;
                console.log("   ✅ Parent OTP verification API call successful.");
                
                // Test switch-child
                const switchRes = await fetch(`${API_BASE}/api/auth/parent/switch-child`, {
                    method: "POST",
                    headers: { 
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${verifyData.token}`
                    },
                    body: JSON.stringify({ studentId: testStudent.rows[0].id })
                });
                const switchData = await switchRes.json();
                if (switchData.success && switchData.token) {
                    report.parentSwitchChild = true;
                    console.log("   ✅ Parent switch child API call successful.");
                } else {
                    console.log("   ❌ Parent switch child failed:", switchData);
                }
            } else {
                console.log("   ❌ Parent OTP verify failed:", verifyData);
            }
        }

        // --------------------------------------------------
        // TEST 3: TRANSACTION-SAFE STUDENT CREATION
        // --------------------------------------------------
        console.log("\n[TEST 3] Verifying Transaction-safe Student Creation & Mapping...");
        
        // Log in as Faculty/Admin to get credentials.
        // Let's ensure a test Faculty exists
        const testFacultyEmail = "testfaculty@gsruniverse.com";
        const passwordHash = await bcrypt.hash("password123", 10);
        await pool.query("DELETE FROM public.faculty WHERE email = $1", [testFacultyEmail]);
        const testFaculty = await pool.query(`
            INSERT INTO public.faculty (employee_id, faculty_name, email, password_hash, role, is_active)
            VALUES ('FACVERIFY', 'Verification Faculty', $1, $2, 'FACULTY', true)
            RETURNING id
        `, [testFacultyEmail, passwordHash]);
        
        // Log in faculty via API
        const facultyLoginRes = await fetch(`${API_BASE}/api/auth/faculty/login`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ email: testFacultyEmail, password: "password123" })
        });
        const facultyLoginData = await facultyLoginRes.json();
        
        if (facultyLoginData.success && facultyLoginData.token) {
            const facultyToken = facultyLoginData.token;

            // Create a student via faculty token
            const studentPayload = {
                admission_no: "GSR_TEST_TRANS",
                student_name: "Transactional Student",
                class_name: "9th",
                section: "B",
                primary_parent_name: "Trans Parent",
                primary_parent_mobile: "9000100020",
                parent_email: "trans@parent.com",
                total_fee: 15000
            };

            const createStudRes = await fetch(`${API_BASE}/api/students/create`, {
                method: "POST",
                headers: { 
                    "Content-Type": "application/json",
                    "Authorization": `Bearer ${facultyToken}`
                },
                body: JSON.stringify(studentPayload)
            });
            const createStudData = await createStudRes.json();
            
            if (createStudData.success && createStudData.student.student_class_mapping_id) {
                console.log("   ✅ Student created successfully via API.");
                
                // Query database to verify mapping and fees table entries
                const mapCheck = await pool.query(
                    "SELECT * FROM public.student_class_mapping WHERE id = $1 AND is_current = true",
                    [createStudData.student.student_class_mapping_id]
                );
                
                const feeCheck = await pool.query(
                    "SELECT * FROM public.fees WHERE student_class_mapping_id = $1",
                    [createStudData.student.student_class_mapping_id]
                );

                if (mapCheck.rows.length > 0 && feeCheck.rows.length > 0) {
                    report.studentCreateTransaction = true;
                    console.log("   ✅ Transaction integrity verified: mappings and initial fees initialized.");
                } else {
                    console.log("   ❌ Inconsistent transaction state in DB.");
                }
                
                // --------------------------------------------------
                // TEST 4: BARCODE SCAN ATTENDANCE
                // --------------------------------------------------
                console.log("\n[TEST 4] Verifying Barcode/QR scan check-in...");
                
                const scanRes = await fetch(`${API_BASE}/api/attendance/scan`, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${facultyToken}`
                    },
                    body: JSON.stringify({
                        barcode: "GSR_TEST_TRANS",
                        session: "Morning",
                        period_number: 1,
                        subject: "Morning Roll Call"
                    })
                });
                const scanData = await scanRes.json();
                
                if (scanData.success && scanData.attendance) {
                    // Check if session column is set
                    if (scanData.attendance.session === "Morning" && scanData.attendance.status === "Present") {
                        report.attendanceScanBarcode = true;
                        console.log("   ✅ Barcode scan attendance processed. session column verified.");
                    }
                } else {
                    console.log("   ❌ Barcode scan failed:", scanData);
                }

                // --------------------------------------------------
                // TEST 5: STUDENT PROMOTION WITH OLD DUES CARRY OVER
                // --------------------------------------------------
                console.log("\n[TEST 5] Verifying Student Promotion Flow...");

                // Setup destination class and academic year
                const destAy = await pool.query(`
                    INSERT INTO public.academic_years (id, year_name, start_date, end_date, is_current)
                    VALUES (2, '2027-2028', '2027-06-01', '2028-04-30', false)
                    ON CONFLICT (id) DO UPDATE SET year_name = '2027-2028'
                    RETURNING id
                `);

                const destClass = await pool.query(`
                    INSERT INTO public.classes (id, class_name, section, academic_year)
                    VALUES (999, '10th', 'B', '2027-2028')
                    ON CONFLICT (id) DO UPDATE SET class_name='10th'
                    RETURNING id
                `);

                // Set mock dues for the student
                await pool.query(
                    "UPDATE public.fees SET pending_amount = 4500.00 WHERE student_class_mapping_id = $1",
                    [createStudData.student.student_class_mapping_id]
                );

                // Perform promotion via API
                const promoteRes = await fetch(`${API_BASE}/api/students/promote`, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${facultyToken}`
                    },
                    body: JSON.stringify({
                        current_academic_year_id: ayId,
                        destination_academic_year_id: destAy.rows[0].id,
                        current_class_id: createStudData.student.class_id,
                        destination_class_id: destClass.rows[0].id,
                        student_ids: [createStudData.student.id],
                        new_fee_amount: 18000.00
                    })
                });
                const promoteData = await promoteRes.json();
                
                if (promoteData.success) {
                    // Check database if new mapping is active, old mapping is deactivated, 
                    // and outstanding dues remarks are logged
                    const oldMap = await pool.query(
                        "SELECT is_current, promoted_by FROM public.student_class_mapping WHERE id = $1",
                        [createStudData.student.student_class_mapping_id]
                    );

                    const newMap = await pool.query(
                        "SELECT id FROM public.student_class_mapping WHERE student_id = $1 AND class_id = $2 AND is_current = true",
                        [createStudData.student.id, destClass.rows[0].id]
                    );

                    if (newMap.rows.length > 0) {
                        const newFee = await pool.query(
                            "SELECT remarks FROM public.fees WHERE student_class_mapping_id = $1",
                            [newMap.rows[0].id]
                        );

                        if (!oldMap.rows[0].is_current && newFee.rows[0].remarks.includes("Prev outstanding dues carried over: $4500")) {
                            report.studentPromotion = true;
                            console.log("   ✅ Student promotion verified. Historical records preserved and dues carried forward.");
                        }
                    }
                } else {
                    console.log("   ❌ Student promotion failed:", promoteData);
                }

            } else {
                console.log("   ❌ Create student API request failed:", createStudData);
            }
        } else {
            console.log("   ❌ Faculty Login failed:", facultyLoginData);
        }

        // --------------------------------------------------
        // TEST 6: FACULTY FORGOT PASSWORD
        // --------------------------------------------------
        console.log("\n[TEST 6] Verifying Faculty Forgot Password Workflow...");
        
        const forgotRes = await fetch(`${API_BASE}/api/auth/faculty/forgot-password`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ email: testFacultyEmail })
        });
        const forgotData = await forgotRes.json();
        
        if (forgotData.success) {
            report.facultyForgotPassword = true;
            console.log("   ✅ Forgot password link dispatch successful.");
        } else {
            console.log("   ❌ Forgot password workflow failed:", forgotData);
        }

    } catch (err) {
        console.error("Critical test exception:", err);
    } finally {
        // Clean up mock data
        console.log("\n[CLEANUP] Purging test entries...");
        await pool.query("DELETE FROM public.students WHERE admission_no IN ('TESTBARCODE', 'GSR_TEST_TRANS')");
        await pool.query("DELETE FROM public.faculty WHERE email = 'testfaculty@gsruniverse.com'");
        await pool.query("DELETE FROM public.otps WHERE mobile = '9988776655'");
        await pool.end();
        
        console.log("\n==================================================");
        console.log("📊 FINAL VERIFICATION METRICS SUMMARY");
        console.log("==================================================");
        console.log(`1. Database Tables Check   : ${report.dbTables ? "PASS ✅" : "FAIL ❌"}`);
        console.log(`2. Database Indexes Check  : ${report.dbIndexes ? "PASS ✅" : "FAIL ❌"}`);
        console.log(`3. Database Triggers Check : ${report.dbTriggers ? "PASS ✅" : "FAIL ❌"}`);
        console.log(`4. Parent OTP Sending Check: ${report.parentOtpSend ? "PASS ✅" : "FAIL ❌"}`);
        console.log(`5. Parent OTP Verify Check : ${report.parentOtpVerify ? "PASS ✅" : "FAIL ❌"}`);
        console.log(`6. Parent Switch Child     : ${report.parentSwitchChild ? "PASS ✅" : "FAIL ❌"}`);
        console.log(`7. Student Transaction Check: ${report.studentCreateTransaction ? "PASS ✅" : "FAIL ❌"}`);
        console.log(`8. Attendance Barcode Scan : ${report.attendanceScanBarcode ? "PASS ✅" : "FAIL ❌"}`);
        console.log(`9. Student Promotion Check : ${report.studentPromotion ? "PASS ✅" : "FAIL ❌"}`);
        console.log(`10. Faculty Forgot Pass Flow: ${report.facultyForgotPassword ? "PASS ✅" : "FAIL ❌"}`);
        console.log("==================================================");
    }
}

runTests();
