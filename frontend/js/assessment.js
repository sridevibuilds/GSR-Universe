// =====================================================
// assessments.js
// Part 1
// Initialization & Load Dropdown Data
// =====================================================

// JWT Token
const token = localStorage.getItem("token");

if (!token) {
    window.location.href = "index.html";
}

// API Base URL
const API_BASE_URL = "http://localhost:5000/api";

// =====================================================
// DOM Elements
// =====================================================

const classSelect = document.getElementById("classSelect");
const academicYearSelect = document.getElementById("academicYearSelect");
const subjectSelect = document.getElementById("subjectSelect");

const assessmentType = document.getElementById("assessmentType");
const totalMarks = document.getElementById("totalMarks");
const assessmentDate = document.getElementById("assessmentDate");

const saveAssessmentBtn = document.getElementById("saveAssessmentBtn");
const clearAssessmentBtn = document.getElementById("clearAssessmentBtn");

const assessmentTableBody = document.getElementById("assessmentTableBody");
const searchAssessment = document.getElementById("searchAssessment");

// =====================================================
// Global Variables
// =====================================================

let editingAssessmentId = null;

// =====================================================
// Load Classes
// =====================================================

async function loadClasses() {

    try {

        const response = await fetch(
            `${API_BASE_URL}/classes`,
            {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            }
        );

        const result = await response.json();

        const classes = result.data || result;

        classSelect.innerHTML =
            `<option value="">Select Class</option>`;

        classes.forEach(cls => {

            classSelect.innerHTML += `
                <option value="${cls.id}">
                    ${cls.class_name}
                </option>
            `;

        });

    } catch (error) {

        console.error("Load Classes Error:", error);

    }

}

// =====================================================
// Load Academic Years
// =====================================================

async function loadAcademicYears() {

    try {

        const response = await fetch(
            `${API_BASE_URL}/academic-years`,
            {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            }
        );

        const result = await response.json();

        const years = result.data || result;

        academicYearSelect.innerHTML =
            `<option value="">Select Academic Year</option>`;

        years.forEach(year => {

            academicYearSelect.innerHTML += `
                <option value="${year.id}">
                    ${year.year_name}
                </option>
            `;

        });

    } catch (error) {

        console.error("Load Academic Years Error:", error);

    }

}

// =====================================================
// Load Subjects
// =====================================================

async function loadSubjects() {

    try {

        const response = await fetch(
            `${API_BASE_URL}/subjects`,
            {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            }
        );

        const result = await response.json();

        const subjects = result.data || result;

        subjectSelect.innerHTML =
            `<option value="">Select Subject</option>`;

        subjects.forEach(subject => {

            subjectSelect.innerHTML += `
                <option value="${subject.id}">
                    ${subject.subject_name}
                </option>
            `;

        });

    } catch (error) {

        console.error("Load Subjects Error:", error);

    }

}

// =====================================================
// Initial Load
// =====================================================

document.addEventListener("DOMContentLoaded", () => {

    loadClasses();
    loadAcademicYears();
    loadSubjects();

});
// =====================================================
// assessments.js
// Part 2
// Load Assessments | Search | Edit
// =====================================================

// =====================================================
// Load All Assessments
// =====================================================

async function loadAssessments() {

    try {

        const response = await fetch(
            `${API_BASE_URL}/assessments`,
            {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            }
        );

        const result = await response.json();

        assessmentTableBody.innerHTML = "";

        if (!result.success || result.data.length === 0) {

            assessmentTableBody.innerHTML = `
                <tr>
                    <td colspan="10" class="text-center">
                        No Assessments Available
                    </td>
                </tr>
            `;

            return;

        }

        result.data.forEach((assessment, index) => {

            assessmentTableBody.innerHTML += `

                <tr>

                    <td>${index + 1}</td>

                    <td>${assessment.class_name}</td>

                    <td>${assessment.section}</td>

                    <td>${assessment.year_name}</td>

                    <td>${assessment.subject_name}</td>

                    <td>${assessment.assessment_type}</td>

                    <td>${assessment.total_marks}</td>

                    <td>${assessment.assessment_date}</td>

                    <td>${assessment.created_by}</td>

                    <td>

                        <button
                            class="btn btn-warning btn-sm"
                            onclick="editAssessment(${assessment.id})">

                            Edit

                        </button>

                        <button
                            class="btn btn-danger btn-sm ms-1"
                            onclick="deleteAssessment(${assessment.id})">

                            Delete

                        </button>

                    </td>

                </tr>

            `;

        });

    } catch (error) {

        console.error("Load Assessments Error:", error);

        assessmentTableBody.innerHTML = `
            <tr>
                <td colspan="10" class="text-center text-danger">
                    Failed to load assessments.
                </td>
            </tr>
        `;

    }

}

// =====================================================
// Search Assessment
// =====================================================

searchAssessment.addEventListener("keyup", function () {

    const keyword = this.value.toLowerCase();

    const rows = assessmentTableBody.querySelectorAll("tr");

    rows.forEach(row => {

        const text = row.innerText.toLowerCase();

        row.style.display = text.includes(keyword)
            ? ""
            : "none";

    });

});

// =====================================================
// Edit Assessment
// =====================================================

async function editAssessment(id) {

    try {

        const response = await fetch(
            `${API_BASE_URL}/assessments/${id}`,
            {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            }
        );

        const result = await response.json();

        if (!result.success) {

            alert("Unable to fetch assessment.");

            return;

        }

        const assessment = result.data;

        editingAssessmentId = assessment.id;

        classSelect.value = assessment.class_id;
        academicYearSelect.value = assessment.academic_year_id;
        subjectSelect.value = assessment.subject_id;

        assessmentType.value = assessment.assessment_type;
        totalMarks.value = assessment.total_marks;

        assessmentDate.value =
            assessment.assessment_date
                ? assessment.assessment_date.split("T")[0]
                : "";

        saveAssessmentBtn.textContent = "Update Assessment";

    } catch (error) {

        console.error("Edit Assessment Error:", error);

        alert("Failed to load assessment details.");

    }

}

// =====================================================
// Initial Assessment Load
// =====================================================

document.addEventListener("DOMContentLoaded", () => {

    loadAssessments();

});
// =====================================================
// assessments.js
// Part 3
// Create | Update | Delete | Clear Form
// =====================================================

// Faculty ID (Stored during Login)
const createdBy =
    localStorage.getItem("faculty_id") ||
    localStorage.getItem("user_id");

// =====================================================
// Save / Update Assessment
// =====================================================

async function saveAssessment() {

    const assessmentData = {

        class_id: classSelect.value,
        academic_year_id: academicYearSelect.value,
        subject_id: subjectSelect.value,
        assessment_type: assessmentType.value,
        total_marks: totalMarks.value,
        assessment_date: assessmentDate.value,
        created_by: createdBy

    };

    // Validation

    if (!assessmentData.class_id) {
        alert("Please select class.");
        return;
    }

    if (!assessmentData.academic_year_id) {
        alert("Please select academic year.");
        return;
    }

    if (!assessmentData.subject_id) {
        alert("Please select subject.");
        return;
    }

    if (!assessmentData.assessment_type) {
        alert("Please select assessment type.");
        return;
    }

    if (!assessmentData.total_marks) {
        alert("Please enter total marks.");
        return;
    }

    if (!assessmentData.assessment_date) {
        alert("Please select assessment date.");
        return;
    }

    if (!assessmentData.created_by) {
        alert("Faculty information not found.");
        return;
    }

    try {

        let response;

        // ==========================
        // UPDATE
        // ==========================

        if (editingAssessmentId) {

            response = await fetch(

                `${API_BASE_URL}/assessments/${editingAssessmentId}`,

                {

                    method: "PUT",

                    headers: {

                        "Content-Type": "application/json",
                        Authorization: `Bearer ${token}`

                    },

                    body: JSON.stringify({

                        class_id: assessmentData.class_id,
                        academic_year_id: assessmentData.academic_year_id,
                        subject_id: assessmentData.subject_id,
                        assessment_type: assessmentData.assessment_type,
                        total_marks: assessmentData.total_marks,
                        assessment_date: assessmentData.assessment_date

                    })

                }

            );

        }

        // ==========================
        // CREATE
        // ==========================

        else {

            response = await fetch(

                `${API_BASE_URL}/assessments`,

                {

                    method: "POST",

                    headers: {

                        "Content-Type": "application/json",
                        Authorization: `Bearer ${token}`

                    },

                    body: JSON.stringify(assessmentData)

                }

            );

        }

        const result = await response.json();

        if (result.success) {

            alert(result.message);

            clearAssessmentForm();

            loadAssessments();

        } else {

            alert(result.message);

        }

    } catch (error) {

        console.error("Save Assessment Error:", error);

        alert("Unable to save assessment.");

    }

}

// =====================================================
// Delete Assessment
// =====================================================

async function deleteAssessment(id) {

    const confirmDelete = confirm(
        "Are you sure you want to delete this assessment?"
    );

    if (!confirmDelete) return;

    try {

        const response = await fetch(

            `${API_BASE_URL}/assessments/${id}`,

            {

                method: "DELETE",

                headers: {

                    Authorization: `Bearer ${token}`

                }

            }

        );

        const result = await response.json();

        if (result.success) {

            alert(result.message);

            loadAssessments();

        } else {

            alert(result.message);

        }

    } catch (error) {

        console.error("Delete Assessment Error:", error);

        alert("Unable to delete assessment.");

    }

}

// =====================================================
// Clear Form
// =====================================================

function clearAssessmentForm() {

    editingAssessmentId = null;

    classSelect.value = "";
    academicYearSelect.value = "";
    subjectSelect.value = "";

    assessmentType.value = "";
    totalMarks.value = "";
    assessmentDate.value = "";

    saveAssessmentBtn.textContent = "Save Assessment";

}

// =====================================================
// Events
// =====================================================

saveAssessmentBtn.addEventListener(
    "click",
    saveAssessment
);

clearAssessmentBtn.addEventListener(
    "click",
    clearAssessmentForm
);