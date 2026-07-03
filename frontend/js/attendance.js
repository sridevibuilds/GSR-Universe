// ======================================================
// attendance.js
// Part 1
// ======================================================

// JWT Token
const token = localStorage.getItem("token");

if (!token) {
    window.location.href = "index.html";
}

// API Base URL
const API_BASE_URL = "http://localhost:5000/api";

// DOM Elements
const classSelect = document.getElementById("classSelect");
const sectionSelect = document.getElementById("sectionSelect");
const periodSelect = document.getElementById("periodSelect");
const attendanceDate = document.getElementById("attendanceDate");

const attendanceTableBody = document.getElementById("attendanceTableBody");

const saveAttendanceBtn = document.getElementById("saveAttendanceBtn");

// Attendance Array
let attendanceData = [];

// Set today's date
attendanceDate.value = new Date().toISOString().split("T")[0];

// ======================================================
// Load Classes
// ======================================================

async function loadClasses() {

    try {

        const response = await fetch(`${API_BASE_URL}/classes`, {
            headers: {
                Authorization: `Bearer ${token}`
            }
        });

        const data = await response.json();

        classSelect.innerHTML =
            `<option value="">Select Class</option>`;

        data.forEach(cls => {

            classSelect.innerHTML += `
                <option value="${cls.class_id}">
                    ${cls.class_name}
                </option>
            `;

        });

    } catch (error) {

        console.error("Load Classes Error:", error);

    }

}

// ======================================================
// Load Sections
// ======================================================

async function loadSections(classId) {

    if (!classId) {

        sectionSelect.innerHTML =
            `<option value="">Select Section</option>`;

        return;

    }

    try {

        const response = await fetch(
            `${API_BASE_URL}/sections/class/${classId}`,
            {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            }
        );

        const data = await response.json();

        sectionSelect.innerHTML =
            `<option value="">Select Section</option>`;

        data.forEach(section => {

            sectionSelect.innerHTML += `
                <option value="${section.section_id}">
                    ${section.section_name}
                </option>
            `;

        });

    } catch (error) {

        console.error("Load Sections Error:", error);

    }

}

// ======================================================
// Events
// ======================================================

classSelect.addEventListener("change", () => {

    loadSections(classSelect.value);

});

attendanceDate.addEventListener("change", () => {

    attendanceTableBody.innerHTML = "";

});

periodSelect.addEventListener("change", () => {

    attendanceTableBody.innerHTML = "";

});

// Initial Load
loadClasses();
// ======================================================
// attendance.js
// Part 2
// Load Students & Build Attendance Table
// ======================================================

// ======================================================
// Load Students
// ======================================================

async function loadStudents() {

    const classId = classSelect.value;
    const sectionId = sectionSelect.value;

    if (!classId || !sectionId) {
        attendanceTableBody.innerHTML = "";
        return;
    }

    try {

        const response = await fetch(
            `${API_BASE_URL}/students/class/${classId}/section/${sectionId}`,
            {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            }
        );

        const students = await response.json();

        attendanceData = [];

        attendanceTableBody.innerHTML = "";

        if (!students.length) {

            attendanceTableBody.innerHTML = `
                <tr>
                    <td colspan="5" class="text-center">
                        No Students Found
                    </td>
                </tr>
            `;

            return;
        }

        students.forEach((student, index) => {

            attendanceData.push({
                student_id: student.student_id,
                status: "Present"
            });

            attendanceTableBody.innerHTML += `
                <tr>

                    <td>${index + 1}</td>

                    <td>${student.admission_no}</td>

                    <td>${student.student_name}</td>

                    <td>

                        <div class="form-check form-check-inline">

                            <input
                                class="form-check-input"
                                type="radio"
                                name="attendance_${student.student_id}"
                                value="Present"
                                checked
                                onchange="updateAttendance(${student.student_id}, 'Present')">

                            <label class="form-check-label">
                                Present
                            </label>

                        </div>

                        <div class="form-check form-check-inline">

                            <input
                                class="form-check-input"
                                type="radio"
                                name="attendance_${student.student_id}"
                                value="Absent"
                                onchange="updateAttendance(${student.student_id}, 'Absent')">

                            <label class="form-check-label">
                                Absent
                            </label>

                        </div>

                    </td>

                </tr>
            `;

        });

    } catch (error) {

        console.error("Load Students Error:", error);

        attendanceTableBody.innerHTML = `
            <tr>
                <td colspan="5" class="text-center text-danger">
                    Failed to load students.
                </td>
            </tr>
        `;

    }

}

// ======================================================
// Update Attendance
// ======================================================

function updateAttendance(studentId, status) {

    const student = attendanceData.find(
        item => item.student_id === studentId
    );

    if (student) {
        student.status = status;
    }

}

// ======================================================
// Events
// ======================================================

sectionSelect.addEventListener("change", loadStudents);

classSelect.addEventListener("change", () => {

    attendanceTableBody.innerHTML = "";
    attendanceData = [];

});
// ======================================================
// attendance.js
// Part 3
// Save Attendance
// ======================================================

// ======================================================
// Save Attendance
// ======================================================

async function saveAttendance() {

    const classId = classSelect.value;
    const sectionId = sectionSelect.value;
    const period = periodSelect.value;
    const date = attendanceDate.value;

    // Validation

    if (!classId) {
        alert("Please select a class.");
        return;
    }

    if (!sectionId) {
        alert("Please select a section.");
        return;
    }

    if (!period) {
        alert("Please select a period.");
        return;
    }

    if (!date) {
        alert("Please select attendance date.");
        return;
    }

    if (attendanceData.length === 0) {
        alert("No students available.");
        return;
    }

    try {

        const response = await fetch(
            `${API_BASE_URL}/attendance`,
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${token}`
                },
                body: JSON.stringify({
                    class_id: classId,
                    section_id: sectionId,
                    attendance_date: date,
                    period: period,
                    attendance: attendanceData
                })
            }
        );

        const result = await response.json();

        if (response.ok) {

            alert(result.message || "Attendance saved successfully.");

            // Reload latest data
            loadStudents();

        } else {

            alert(result.message || "Failed to save attendance.");

        }

    } catch (error) {

        console.error("Save Attendance Error:", error);

        alert("Server error while saving attendance.");

    }

}

// ======================================================
// Button Event
// ======================================================

if (saveAttendanceBtn) {

    saveAttendanceBtn.addEventListener("click", saveAttendance);

}

// ======================================================
// Initialize
// ======================================================

document.addEventListener("DOMContentLoaded", () => {

    loadClasses();

});