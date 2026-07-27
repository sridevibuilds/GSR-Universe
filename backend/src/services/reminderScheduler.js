// Module 8 Automated Fee Reminders - Reminder Scheduler Service

const db = require("../config/db");
const { initiateFeeReminderCall } = require("./callService");

/**
 * Sweeps all students with outstanding balances, checks scheduling parameters,
 * handles monthly duplicate exclusions, and runs reminder calls.
 */
const runFeeRemindersCheck = async (isManual = false) => {
    try {
        console.log(`[Scheduler] Starting ${isManual ? 'manual' : 'daily'} fee reminders check...`);
        
        // 1. Fetch current active call settings
        const settingsResult = await db.query(
            "SELECT * FROM public.call_settings WHERE id = 1 LIMIT 1"
        );
        
        if (settingsResult.rows.length === 0) {
            console.log("[Scheduler] Call settings not configured. Skipping execution.");
            return;
        }

        const settings = settingsResult.rows[0];

        // Ensure reminder calling is enabled (unless manually triggered)
        if (!settings.is_enabled && !isManual) {
            console.log("[Scheduler] Automated reminders are disabled in settings. Skipping execution.");
            return;
        }

        // 2. Validate calendar range (1st–7th of the month by default) unless manual trigger
        const today = new Date();
        const dayOfMonth = today.getDate();

        if (!isManual && (dayOfMonth < settings.schedule_day_start || dayOfMonth > settings.schedule_day_end)) {
            console.log(`[Scheduler] Day of month (${dayOfMonth}) is outside schedule window (${settings.schedule_day_start} to ${settings.schedule_day_end}). Skipping execution.`);
            return;
        }

        // 3. Fetch active academic year
        const ayResult = await db.query(
            "SELECT id FROM public.academic_years WHERE is_current = true LIMIT 1"
        );

        if (ayResult.rows.length === 0) {
            console.log("[Scheduler] No current active academic year configured. Skipping execution.");
            return;
        }

        const currentAcademicYearId = ayResult.rows[0].id;

        // 4. Query students with outstanding dues in the active academic year
        const pendingQuery = await db.query(
            `SELECT 
                s.id as student_id,
                s.student_name,
                s.primary_parent_mobile as mobile,
                f.pending_amount,
                f.academic_year_id,
                scm.id as student_class_mapping_id
             FROM public.fees f
             JOIN public.student_class_mapping scm ON f.student_class_mapping_id = scm.id
             JOIN public.students s ON scm.student_id = s.id
             WHERE scm.is_current = true 
               AND f.pending_amount > 0 
               AND f.academic_year_id = $1`,
            [currentAcademicYearId]
        );

        console.log(`[Scheduler] Found ${pendingQuery.rows.length} students with pending dues.`);

        let processedCalls = 0;
        let skippedCalls = 0;

        for (const record of pendingQuery.rows) {
            const { student_id, student_name, mobile, pending_amount, academic_year_id } = record;

            // 5. Exclude if a call was already placed to this student in current month (unless manual trigger)
            if (!isManual) {
                const callCheck = await db.query(
                    `SELECT id FROM public.call_history
                     WHERE student_id = $1 
                       AND academic_year_id = $2
                       AND DATE_TRUNC('month', call_date) = DATE_TRUNC('month', CURRENT_DATE)`,
                    [student_id, academic_year_id]
                );

                if (callCheck.rows.length > 0) {
                    skippedCalls++;
                    continue;
                }
            }

            // 6. Dispatch voice call via callService gateway
            try {
                const callResult = await initiateFeeReminderCall(
                    mobile, 
                    student_name, 
                    pending_amount, 
                    "twilio", 
                    settings
                );

                // 7. Insert record in call log history
                await db.query(
                    `INSERT INTO public.call_history
                     (student_id, academic_year_id, parent_mobile, amount_due, status, provider_call_sid)
                     VALUES ($1, $2, $3, $4, $5, $6)`,
                    [
                        student_id,
                        academic_year_id,
                        mobile,
                        pending_amount,
                        callResult.success ? "Initiated" : "Failed",
                        callResult.callSid || null
                    ]
                );

                processedCalls++;
            } catch (err) {
                console.error(`[Scheduler] Call failed for student ${student_name} (${mobile}):`, err.message);
                
                // Log failed attempt details
                await db.query(
                    `INSERT INTO public.call_history
                     (student_id, academic_year_id, parent_mobile, amount_due, status, provider_call_sid)
                     VALUES ($1, $2, $3, $4, 'Failed', $5)`,
                    [student_id, academic_year_id, mobile, pending_amount, `error_${Math.floor(1000 + Math.random()*9000)}`]
                );
            }
        }

        console.log(`[Scheduler] Reminders check execution complete: ${processedCalls} calls placed, ${skippedCalls} skipped.`);

    } catch (error) {
        console.error("[Scheduler] Critical failure in automated fee reminders sweep:", error);
    }
};

module.exports = {
    runFeeRemindersCheck
};
