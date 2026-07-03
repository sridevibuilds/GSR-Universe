// =====================================================
// assignments.js
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

const titleInput = document.getElementById("title");
const descriptionInput = document.getElementById("description");
const submissionDateInput = document.getElementById("submissionDate");

const attachmentNameInput = document.getElementById("attachmentName");
const attachmentPathInput = document.getElementById("attachmentPath");

const saveAssignmentBtn = document.getElementById("saveAssignmentBtn");
const clearAssignmentBtn = document.getElementById("clearAssignmentBtn");

const assignmentTableBody = document.getElementById("assignmentTableBody");
const searchAssignment = document.getElementById("searchAssignment");

// =====================================================
// Global Variables
// =====================================================

let editingAssignmentId = null;

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
// assignments.js
// Part 2
// Load Assignments | Search | Edit
// =====================================================

// =====================================================
// Load All Assignments
// =====================================================

async function loadAssignments() {

    try {

        const response = await fetch(
            `${API_BASE_URL}/assignments`,
            {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            }
        );

        const result = await response.json();

        assignmentTableBody.innerHTML = "";

        if (!result.success || result.data.length === 0) {

            assignmentTableBody.innerHTML = `
                <tr>
                    <td colspan="11" class="text-center">
                        No Assignments Available
                    </td>
                </tr>
            `;

            return;

        }

        result.data.forEach((assignment, index) => {

            assignmentTableBody.innerHTML += `

                <tr>

                    <td>${index + 1}</td>

                    <td>${assignment.class_name}</td>

                    <td>${assignment.section}</td>

                    <td>${assignment.year_name}</td>

                    <td>${assignment.subject_name}</td>

                    <td>${assignment.title}</td>

                    <td>${assignment.description}</td>

                    <td>${assignment.submission_date}</td>

                    <td>${assignment.attachment_name || "-"}</td>

                    <td>${assignment.created_by}</td>

                    <td>

                        <button
                            class="btn btn-warning btn-sm"
                            onclick="editAssignment(${assignment.id})">

                            Edit

                        </button>

                        <button
                            class="btn btn-danger btn-sm ms-1"
                            onclick="deleteAssignment(${assignment.id})">

                            Delete

                        </button>

                    </td>

                </tr>

            `;

        });

    } catch (error) {

        console.error("Load Assignments Error:", error);

        assignmentTableBody.innerHTML = `
            <tr>
                <td colspan="11"
                    class="text-center text-danger">

                    Failed to load assignments.

                </td>
            </tr>
        `;

    }

}

// =====================================================
// Search Assignment
// =====================================================

searchAssignment.addEventListener("keyup", function () {

    const keyword = this.value.toLowerCase();

    const rows = assignmentTableBody.querySelectorAll("tr");

    rows.forEach(row => {

        const text = row.innerText.toLowerCase();

        row.style.display = text.includes(keyword)
            ? ""
            : "none";

    });

});

// =====================================================
// Edit Assignment
// =====================================================

async function editAssignment(id) {

    try {

        const response = await fetch(
            `${API_BASE_URL}/assignments/${id}`,
            {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            }
        );

        const result = await response.json();

        if (!result.success) {

            alert("Unable to fetch assignment.");

            return;

        }

        const assignment = result.data;

        editingAssignmentId = assignment.id;

        classSelect.value = assignment.class_id;
        academicYearSelect.value = assignment.academic_year_id;
        subjectSelect.value = assignment.subject_id;

        titleInput.value = assignment.title;
        descriptionInput.value = assignment.description;

        submissionDateInput.value =
            assignment.submission_date
                ? assignment.submission_date.split("T")[0]
                : "";

        attachmentNameInput.value =
            assignment.attachment_name || "";

        attachmentPathInput.value =
            assignment.attachment_path || "";

        saveAssignmentBtn.textContent =
            "Update Assignment";

    } catch (error) {

        console.error("Edit Assignment Error:", error);

        alert("Failed to load assignment details.");

    }

}

// =====================================================
// Initial Assignment Load
// =====================================================

document.addEventListener("DOMContentLoaded", () => {

    loadAssignments();

});
// =====================================================
// assignments.js
// Part 3
// Create | Update | Delete | Clear Form
// =====================================================

// Faculty ID (Stored during Login)
const createdBy =
    localStorage.getItem("faculty_id") ||
    localStorage.getItem("user_id");

// =====================================================
// Save / Update Assignment
// =====================================================

async function saveAssignment() {

    const assignmentData = {

        class_id: classSelect.value,
        academic_year_id: academicYearSelect.value,
        subject_id: subjectSelect.value,
        title: titleInput.value.trim(),
        description: descriptionInput.value.trim(),
        submission_date: submissionDateInput.value,
        attachment_name: attachmentNameInput.value.trim(),
        attachment_path: attachmentPathInput.value.trim(),
        created_by: createdBy

    };

    // Validation

    if (!assignmentData.class_id) {
        alert("Please select class.");
        return;
    }

    if (!assignmentData.academic_year_id) {
        alert("Please select academic year.");
        return;
    }

    if (!assignmentData.subject_id) {
        alert("Please select subject.");
        return;
    }

    if (!assignmentData.title) {
        alert("Please enter assignment title.");
        return;
    }

    if (!assignmentData.description) {
        alert("Please enter assignment description.");
        return;
    }

    if (!assignmentData.submission_date) {
        alert("Please select submission date.");
        return;
    }

    if (!assignmentData.created_by) {
        alert("Faculty information not found.");
        return;
    }

    try {

        let response;

        // UPDATE

        if (editingAssignmentId) {

            response = await fetch(

                `${API_BASE_URL}/assignments/${editingAssignmentId}`,

                {
                    method: "PUT",

                    headers: {
                        "Content-Type": "application/json",
                        Authorization: `Bearer ${token}`
                    },

                    body: JSON.stringify({

                        title: assignmentData.title,
                        description: assignmentData.description,
                        submission_date: assignmentData.submission_date

                    })

                }

            );

        }

        // CREATE

        else {

            response = await fetch(

                `${API_BASE_URL}/assignments`,

                {

                    method: "POST",

                    headers: {

                        "Content-Type": "application/json",
                        Authorization: `Bearer ${token}`

                    },

                    body: JSON.stringify(assignmentData)

                }

            );

        }

        const result = await response.json();

        if (result.success) {

            alert(result.message);

            clearAssignmentForm();

            loadAssignments();

        } else {

            alert(result.message);

        }

    } catch (error) {

        console.error("Save Assignment Error:", error);

        alert("Unable to save assignment.");

    }

}

// =====================================================
// Delete Assignment
// =====================================================

async function deleteAssignment(id) {

    const confirmDelete = confirm(
        "Are you sure you want to delete this assignment?"
    );

    if (!confirmDelete) return;

    try {

        const response = await fetch(

            `${API_BASE_URL}/assignments/${id}`,

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

            loadAssignments();

        } else {

            alert(result.message);

        }

    } catch (error) {

        console.error("Delete Assignment Error:", error);

        alert("Unable to delete assignment.");

    }

}

// =====================================================
// Clear Form
// =====================================================

function clearAssignmentForm() {

    editingAssignmentId = null;

    classSelect.value = "";
    academicYearSelect.value = "";
    subjectSelect.value = "";

    titleInput.value = "";
    descriptionInput.value = "";
    submissionDateInput.value = "";

    attachmentNameInput.value = "";
    attachmentPathInput.value = "";

    saveAssignmentBtn.textContent = "Save Assignment";

}

// =====================================================
// Events
// =====================================================

saveAssignmentBtn.addEventListener(
    "click",
    saveAssignment
);

clearAssignmentBtn.addEventListener(
    "click",
    clearAssignmentForm
);