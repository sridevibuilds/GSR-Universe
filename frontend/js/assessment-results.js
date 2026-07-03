// =====================================================
// assessment-results.js
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

const assessmentSelect = document.getElementById("assessmentSelect");
const studentMappingSelect = document.getElementById("studentMappingSelect");

const marksObtained = document.getElementById("marksObtained");
const remarks = document.getElementById("remarks");

const saveResultBtn = document.getElementById("saveResultBtn");
const clearResultBtn = document.getElementById("clearResultBtn");

const resultTableBody = document.getElementById("resultTableBody");
const searchResult = document.getElementById("searchResult");

// =====================================================
// Global Variables
// =====================================================

let editingResultId = null;

// =====================================================
// Load Assessments
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

        assessmentSelect.innerHTML =
            `<option value="">Select Assessment</option>`;

        const assessments = result.data || [];

        assessments.forEach(item => {

            assessmentSelect.innerHTML += `
                <option value="${item.id}">
                    ${item.assessment_type} -
                    ${item.subject_name}
                </option>
            `;

        });

    } catch (error) {

        console.error("Load Assessments Error:", error);

    }

}

// =====================================================
// Load Student Mapping
// =====================================================

async function loadStudentMappings() {

    try {

        const response = await fetch(
            `${API_BASE_URL}/student-class-mapping`,
            {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            }
        );

        const result = await response.json();

        studentMappingSelect.innerHTML =
            `<option value="">Select Student</option>`;

        const students = result.data || [];

        students.forEach(student => {

            studentMappingSelect.innerHTML += `
                <option value="${student.id}">
                    ${student.student_name}
                    -
                    ${student.class_name}
                    ${student.section}
                </option>
            `;

        });

    } catch (error) {

        console.error("Load Student Mapping Error:", error);

    }

}

// =====================================================
// Initial Load
// =====================================================

document.addEventListener("DOMContentLoaded", () => {

    loadAssessments();
    loadStudentMappings();

});
// =====================================================
// assessment-results.js
// Part 2
// Load Results | Search | Edit
// =====================================================

// =====================================================
// Load All Assessment Results
// =====================================================

async function loadAssessmentResults() {

    try {

        const response = await fetch(
            `${API_BASE_URL}/assessment-results`,
            {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            }
        );

        const result = await response.json();

        resultTableBody.innerHTML = "";

        if (!result.success || result.data.length === 0) {

            resultTableBody.innerHTML = `
                <tr>
                    <td colspan="10" class="text-center">
                        No Assessment Results Available
                    </td>
                </tr>
            `;

            return;

        }

        result.data.forEach((item, index) => {

            resultTableBody.innerHTML += `

                <tr>

                    <td>${index + 1}</td>

                    <td>${item.student_name}</td>

                    <td>${item.class_name}</td>

                    <td>${item.section}</td>

                    <td>${item.subject_name}</td>

                    <td>${item.assessment_type}</td>

                    <td>${item.total_marks}</td>

                    <td>${item.marks_obtained}</td>

                    <td>${item.remarks || "-"}</td>

                    <td>

                        <button
                            class="btn btn-warning btn-sm"
                            onclick="editAssessmentResult(${item.id})">

                            Edit

                        </button>

                        <button
                            class="btn btn-danger btn-sm ms-1"
                            onclick="deleteAssessmentResult(${item.id})">

                            Delete

                        </button>

                    </td>

                </tr>

            `;

        });

    } catch (error) {

        console.error("Load Assessment Results Error:", error);

        resultTableBody.innerHTML = `
            <tr>
                <td colspan="10" class="text-center text-danger">
                    Failed to load assessment results.
                </td>
            </tr>
        `;

    }

}

// =====================================================
// Search Assessment Results
// =====================================================

searchResult.addEventListener("keyup", function () {

    const keyword = this.value.toLowerCase();

    const rows = resultTableBody.querySelectorAll("tr");

    rows.forEach(row => {

        const text = row.innerText.toLowerCase();

        row.style.display =
            text.includes(keyword)
                ? ""
                : "none";

    });

});

// =====================================================
// Edit Assessment Result
// =====================================================

async function editAssessmentResult(id) {

    try {

        const response = await fetch(
            `${API_BASE_URL}/assessment-results/${id}`,
            {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            }
        );

        const result = await response.json();

        if (!result.success) {

            alert("Unable to fetch assessment result.");

            return;

        }

        const data = result.data;

        editingResultId = data.id;

        assessmentSelect.value = data.assessment_id;
        studentMappingSelect.value =
            data.student_class_mapping_id;

        marksObtained.value =
            data.marks_obtained;

        remarks.value =
            data.remarks || "";

        saveResultBtn.textContent =
            "Update Result";

    } catch (error) {

        console.error(
            "Edit Assessment Result Error:",
            error
        );

        alert(
            "Failed to load assessment result."
        );

    }

}

// =====================================================
// Initial Load
// =====================================================

document.addEventListener("DOMContentLoaded", () => {

    loadAssessmentResults();

});
// =====================================================
// assessment-results.js
// Part 3
// Create | Update | Delete | Clear Form
// =====================================================

// =====================================================
// Save / Update Assessment Result
// =====================================================

async function saveAssessmentResult() {

    const resultData = {

        assessment_id: assessmentSelect.value,
        student_class_mapping_id: studentMappingSelect.value,
        marks_obtained: marksObtained.value,
        remarks: remarks.value.trim()

    };

    // ==========================
    // Validation
    // ==========================

    if (!resultData.assessment_id) {
        alert("Please select an assessment.");
        return;
    }

    if (!resultData.student_class_mapping_id) {
        alert("Please select a student.");
        return;
    }

    if (!resultData.marks_obtained) {
        alert("Please enter marks obtained.");
        return;
    }

    try {

        let response;

        // ==========================
        // UPDATE
        // ==========================

        if (editingResultId) {

            response = await fetch(

                `${API_BASE_URL}/assessment-results/${editingResultId}`,

                {

                    method: "PUT",

                    headers: {

                        "Content-Type": "application/json",
                        Authorization: `Bearer ${token}`

                    },

                    body: JSON.stringify({

                        marks_obtained: resultData.marks_obtained,
                        remarks: resultData.remarks

                    })

                }

            );

        }

        // ==========================
        // CREATE
        // ==========================

        else {

            response = await fetch(

                `${API_BASE_URL}/assessment-results`,

                {

                    method: "POST",

                    headers: {

                        "Content-Type": "application/json",
                        Authorization: `Bearer ${token}`

                    },

                    body: JSON.stringify(resultData)

                }

            );

        }

        const result = await response.json();

        if (result.success) {

            alert(result.message);

            clearResultForm();

            loadAssessmentResults();

        } else {

            alert(result.message);

        }

    } catch (error) {

        console.error(
            "Save Assessment Result Error:",
            error
        );

        alert(
            "Unable to save assessment result."
        );

    }

}

// =====================================================
// Delete Assessment Result
// =====================================================

async function deleteAssessmentResult(id) {

    const confirmDelete = confirm(
        "Are you sure you want to delete this assessment result?"
    );

    if (!confirmDelete) return;

    try {

        const response = await fetch(

            `${API_BASE_URL}/assessment-results/${id}`,

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

            loadAssessmentResults();

        } else {

            alert(result.message);

        }

    } catch (error) {

        console.error(
            "Delete Assessment Result Error:",
            error
        );

        alert(
            "Unable to delete assessment result."
        );

    }

}

// =====================================================
// Clear Form
// =====================================================

function clearResultForm() {

    editingResultId = null;

    assessmentSelect.value = "";
    studentMappingSelect.value = "";

    marksObtained.value = "";
    remarks.value = "";

    saveResultBtn.textContent = "Save Result";

}

// =====================================================
// Events
// =====================================================

saveResultBtn.addEventListener(
    "click",
    saveAssessmentResult
);

clearResultBtn.addEventListener(
    "click",
    clearResultForm
);