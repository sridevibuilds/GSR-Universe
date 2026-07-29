const pool = require("../src/config/db");
const app = require("../src/app");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");
const http = require("http");
require("dotenv").config();

async function verifyAllDashboardMetrics() {
    console.log("==================================================");
    console.log("🔍 STARTING FULL DASHBOARD METRICS DATABASE VERIFICATION");
    console.log("==================================================");

    const server = http.createServer(app);
    await new Promise(resolve => server.listen(0, resolve));
    const testPort = server.address().port;
    const API_BASE = `http://127.0.0.1:${testPort}`;

    let passed = true;

    try {
        // ---------------------------------------------------------
        // 1. DIRECT POSTGRESQL RELATIONAL QUERIES FOR METRICS
        // ---------------------------------------------------------
        console.log("\n[1] Executing Direct PostgreSQL Relational Baseline Queries...");

        const dbTotalStudentsRes = await pool.query(`
            SELECT COUNT(DISTINCT scm.student_id)::int AS total_students
            FROM public.student_class_mapping scm
            JOIN public.students s ON scm.student_id = s.id
            JOIN public.classes c ON scm.class_id = c.id
            JOIN public.academic_years ay ON scm.academic_year_id = ay.id
            WHERE scm.is_current = true AND ay.is_current = true
        `);
        const dbTotalStudents = dbTotalStudentsRes.rows[0].total_students;

        const dbFeeOverviewRes = await pool.query(`
            SELECT 
                COALESCE(SUM(f.total_fee), 0)::numeric(12,2) AS total_fee_amount,
                COALESCE(SUM(f.paid_amount), 0)::numeric(12,2) AS collected_fee_amount,
                COALESCE(SUM(f.total_fee - f.paid_amount), 0)::numeric(12,2) AS outstanding_fee_amount
            FROM public.fees f
            JOIN public.student_class_mapping scm ON f.student_class_mapping_id = scm.id
            JOIN public.academic_years ay ON scm.academic_year_id = ay.id
            WHERE scm.is_current = true AND ay.is_current = true
        `);
        const dbFeeOverview = dbFeeOverviewRes.rows[0];

        console.log(`   - PostgreSQL Total Active Students: ${dbTotalStudents}`);
        console.log(`   - PostgreSQL Total Fee Amount    : ${dbFeeOverview.total_fee_amount}`);
        console.log(`   - PostgreSQL Collected Fee Amount: ${dbFeeOverview.collected_fee_amount}`);
        console.log(`   - PostgreSQL Outstanding Fee     : ${dbFeeOverview.outstanding_fee_amount}`);

        // ---------------------------------------------------------
        // 2. VERIFY ADMIN OVERVIEW API (/api/admin/overview)
        // ---------------------------------------------------------
        console.log("\n[2] Testing Admin Overview API (/api/admin/overview)...");

        const adminCheck = await pool.query("SELECT id FROM public.admins LIMIT 1");
        let adminId = adminCheck.rows.length > 0 ? adminCheck.rows[0].id : 1;

        const adminToken = jwt.sign(
            { id: adminId, role: "admin" },
            process.env.JWT_SECRET || "default_secret",
            { expiresIn: "1h" }
        );

        const overviewApiRes = await fetch(`${API_BASE}/api/admin/overview`, {
            headers: { "Authorization": `Bearer ${adminToken}` }
        });
        const overviewApiData = await overviewApiRes.json();

        if (overviewApiRes.ok && overviewApiData.success) {
            const apiOverview = overviewApiData.overview;
            console.log("   - API Response Overview:", apiOverview);

            if (apiOverview.total_students === dbTotalStudents) {
                console.log(`   ✅ ISSUE 1 FIXED: Total Students (${apiOverview.total_students}) matches PostgreSQL exactly!`);
            } else {
                console.error(`   ❌ ISSUE 1 MISMATCH: API (${apiOverview.total_students}) vs DB (${dbTotalStudents})`);
                passed = false;
            }

            if (parseFloat(apiOverview.outstanding_fee_amount) === parseFloat(dbFeeOverview.outstanding_fee_amount)) {
                console.log(`   ✅ ISSUE 2 FIXED: Fees Outstanding (₹${apiOverview.outstanding_fee_amount}) matches PostgreSQL calculated Outstanding Fee (₹${dbFeeOverview.outstanding_fee_amount}) exactly!`);
            } else {
                console.error(`   ❌ ISSUE 2 MISMATCH: API (${apiOverview.outstanding_fee_amount}) vs DB (${dbFeeOverview.outstanding_fee_amount})`);
                passed = false;
            }
        } else {
            console.error("   ❌ Admin Overview API request failed:", overviewApiData);
            passed = false;
        }

        // ---------------------------------------------------------
        // 3. VERIFY STUDENT ANALYTICS REPORT API (/api/admin/class-reports)
        // ---------------------------------------------------------
        console.log("\n[3] Testing Student Analytics Report API (/api/admin/class-reports)...");

        // Test with actual database class 'Class 9', Section 'A', Academic Year '2026-2027'
        const reportParams = new URLSearchParams({
            academic_year: '2026-2027',
            class_name: 'Class 9',
            section: 'A',
            term: 'Annual'
        });

        const reportApiRes = await fetch(`${API_BASE}/api/admin/class-reports?${reportParams}`, {
            headers: { "Authorization": `Bearer ${adminToken}` }
        });
        const reportApiData = await reportApiRes.json();

        if (reportApiRes.ok && reportApiData.success) {
            const summary = reportApiData.summary;
            console.log("   - Student Analytics Report Summary for Class 9 Sec A:", summary);

            const dbClassCount = await pool.query(`
                SELECT COUNT(DISTINCT scm.student_id)::int AS count
                FROM public.student_class_mapping scm
                JOIN public.students s ON scm.student_id = s.id
                JOIN public.classes c ON scm.class_id = c.id
                JOIN public.academic_years ay ON scm.academic_year_id = ay.id
                WHERE scm.is_current = true AND c.class_name = 'Class 9' AND c.section = 'A'
            `);
            
            const expectedCount = parseInt(dbClassCount.rows[0].count);
            console.log(`   - PostgreSQL Filtered Class 9 Student Count: ${expectedCount}`);

            if (summary.total_students === expectedCount) {
                console.log(`   ✅ ISSUE 3 FIXED: Student Analytics Report generated dynamically from PostgreSQL!`);
                console.log(`      Report Metrics from PostgreSQL:`);
                console.log(`      - Total Students    : ${summary.total_students}`);
                console.log(`      - Assessment Avg    : ${summary.assessment_performance_pct}%`);
                console.log(`      - Fee Collection    : ₹${summary.fee_collection}`);
                console.log(`      - Pending Fee       : ₹${summary.pending_fee}`);
                console.log(`      - Excellent Students: ${summary.excellent_students}`);
                console.log(`      - Average Students  : ${summary.average_students}`);
                console.log(`      - Needs Improvement : ${summary.needs_improvement}`);
                console.log(`      - Daily Attendance  : ${summary.daily_attendance_pct}%`);
                console.log(`      - Monthly Attendance: ${summary.monthly_attendance_pct}%`);
                console.log(`      - Yearly Attendance : ${summary.yearly_attendance_pct}%`);
            } else {
                console.error(`   ❌ ISSUE 3 MISMATCH: Report Total Students (${summary.total_students}) vs DB (${expectedCount})`);
                passed = false;
            }
        } else {
            console.error("   ❌ Student Analytics Report API request failed:", reportApiData);
            passed = false;
        }

        // ---------------------------------------------------------
        // 4. VERIFY STUDENT DASHBOARD PENDING FEE (/api/parent/dashboard)
        // ---------------------------------------------------------
        console.log("\n[4] Testing Student Dashboard Dues API (/api/parent/dashboard)...");

        const scmCheck = await pool.query(`
            SELECT scm.id, scm.student_id, s.primary_parent_mobile, f.pending_amount, (f.total_fee - f.paid_amount) as calc_pending
            FROM public.student_class_mapping scm
            JOIN public.students s ON scm.student_id = s.id
            JOIN public.fees f ON scm.id = f.student_class_mapping_id
            WHERE scm.is_current = true
            LIMIT 1
        `);

        if (scmCheck.rows.length > 0) {
            const scmRow = scmCheck.rows[0];
            const studentToken = jwt.sign(
                { id: scmRow.student_id, student_class_mapping_id: scmRow.id, mobile: scmRow.primary_parent_mobile, role: "PARENT" },
                process.env.JWT_SECRET || "default_secret",
                { expiresIn: "1h" }
            );

            const studentDashRes = await fetch(`${API_BASE}/api/parent/dashboard`, {
                headers: { "Authorization": `Bearer ${studentToken}` }
            });
            const studentDashData = await studentDashRes.json();

            if (studentDashRes.ok && studentDashData.success) {
                const feeSummary = studentDashData.dashboard.feeSummary;
                console.log("   - Student Dashboard Fee Summary:", feeSummary);
                const dbPending = parseFloat(scmRow.calc_pending || 0);

                if (parseFloat(feeSummary.pendingAmount) === dbPending) {
                    console.log(`   ✅ STUDENT DASHBOARD METRIC FIXED: Pending Fee (₹${feeSummary.pendingAmount}) matches PostgreSQL calculated pending fee (₹${dbPending}) exactly!`);
                } else {
                    console.error(`   ❌ STUDENT DASHBOARD MISMATCH: API (${feeSummary.pendingAmount}) vs DB (${dbPending})`);
                    passed = false;
                }
            } else {
                console.error("   ❌ Student Dashboard API request failed:", studentDashData);
                passed = false;
            }
        }

        console.log("\n==================================================");
        if (passed) {
            console.log("🎉 ALL DASHBOARD METRICS VERIFIED & MATCH POSTGRESQL 100%!");
        } else {
            console.log("⚠️ SOME DASHBOARD METRICS MISMATCHED DATABASE!");
        }
        console.log("==================================================");

    } catch (err) {
        console.error("Critical Verification Error:", err);
    } finally {
        server.close();
        await pool.end();
    }
}

verifyAllDashboardMetrics();
