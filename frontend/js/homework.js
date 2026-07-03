// =====================================================
// homework.js
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
const dueDateInput = document.getElementById("dueDate");

const attachmentNameInput = document.getElementById("attachmentName");
const attachmentPathInput = document.getElementById("attachmentPath");

const saveHomeworkBtn = document.getElementById("saveHomeworkBtn");
const clearHomeworkBtn = document.getElementById("clearHomeworkBtn");

const homeworkTableBody = document.getElementById("homeworkTableBody");
const searchHomework = document.getElementById("searchHomework");

// =====================================================
// Global Variables
// =====================================================

let editingHomeworkId = null;

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

        classSelect.innerHTML =
            `<option value="">Select Class</option>`;

        const classes = result.data || result;

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

        academicYearSelect.innerHTML =
            `<option value="">Select Academic Year</option>`;

        const years = result.data || result;

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

        subjectSelect.innerHTML =
            `<option value="">Select Subject</option>`;

        const subjects = result.data || result;

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
// homework.js
// Part 2
// Load Homework & Search
// =====================================================

// =====================================================
// Load All Homework
// =====================================================

async function loadHomework() {

    try {

        const response = await fetch(
            `${API_BASE_URL}/homework`,
            {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            }
        );

        const result = await response.json();

        homeworkTableBody.innerHTML = "";

        if (!result.success || result.data.length === 0) {

            homeworkTableBody.innerHTML = `
                <tr>
                    <td colspan="11" class="text-center">
                        No Homework Available
                    </td>
                </tr>
            `;

            return;
        }

        result.data.forEach((homework, index) => {

            homeworkTableBody.innerHTML += `

                <tr>

                    <td>${index + 1}</td>

                    <td>${homework.class_name}</td>

                    <td>${homework.section}</td>

                    <td>${homework.year_name}</td>

                    <td>${homework.subject_name}</td>

                    <td>${homework.title}</td>

                    <td>${homework.description}</td>

                    <td>${homework.due_date}</td>

                    <td>${homework.attachment_name || "-"}</td>

                    <td>${homework.created_by}</td>

                    <td>

                        <button
                            class="btn btn-warning btn-sm"
                            onclick="editHomework(${homework.id})">

                            Edit

                        </button>

                        <button
                            class="btn btn-danger btn-sm ms-1"
                            onclick="deleteHomework(${homework.id})">

                            Delete

                        </button>

                    </td>

                </tr>

            `;

        });

    } catch (error) {

        console.error("Load Homework Error:", error);

        homeworkTableBody.innerHTML = `
            <tr>
                <td colspan="11" class="text-center text-danger">
                    Failed to load homework.
                </td>
            </tr>
        `;

    }

}

// =====================================================
// Search Homework
// =====================================================

searchHomework.addEventListener("keyup", function () {

    const value = this.value.toLowerCase();

    const rows = homeworkTableBody.querySelectorAll("tr");

    rows.forEach(row => {

        const text = row.innerText.toLowerCase();

        row.style.display =
            text.includes(value) ? "" : "none";

    });

});

// =====================================================
// Edit Homework
// =====================================================

async function editHomework(id) {

    try {

        const response = await fetch(
            `${API_BASE_URL}/homework/${id}`,
            {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            }
        );

        const result = await response.json();

        if (!result.success) {

            alert("Unable to fetch homework.");

            return;

        }

        const homework = result.data;

        editingHomeworkId = homework.id;

        classSelect.value = homework.class_id;
        academicYearSelect.value = homework.academic_year_id;
        subjectSelect.value = homework.subject_id;

        titleInput.value = homework.title;
        descriptionInput.value = homework.description;
        dueDateInput.value = homework.due_date
            ? homework.due_date.split("T")[0]
            : "";

        attachmentNameInput.value = homework.attachment_name || "";
        attachmentPathInput.value = homework.attachment_path || "";

        saveHomeworkBtn.textContent = "Update Homework";

    } catch (error) {

        console.error("Edit Homework Error:", error);

        alert("Failed to load homework details.");

    }

}

// =====================================================
// Initial Homework Load
// =====================================================

document.addEventListener("DOMContentLoaded", () => {

    loadHomework();

});
// =====================================================
// homework.js
// Part 3
// Save | Update | Delete | Clear Form
// =====================================================

// NOTE:
// created_by should come from the logged-in faculty.
// Replace the line below if you already store the faculty id
// using a different localStorage key.
const createdBy =
    localStorage.getItem("faculty_id") ||
    localStorage.getItem("user_id");

// =====================================================
// Save / Update Homework
// =====================================================

async function saveHomework() {

    const homeworkData = {

        class_id: classSelect.value,
        academic_year_id: academicYearSelect.value,
        subject_id: subjectSelect.value,
        title: titleInput.value.trim(),
        description: descriptionInput.value.trim(),
        due_date: dueDateInput.value,
        attachment_name: attachmentNameInput.value.trim(),
        attachment_path: attachmentPathInput.value.trim(),
        created_by: createdBy

    };

    // Validation

    if (!homeworkData.class_id) {
        alert("Please select a class.");
        return;
    }

    if (!homeworkData.academic_year_id) {
        alert("Please select an academic year.");
        return;
    }

    if (!homeworkData.subject_id) {
        alert("Please select a subject.");
        return;
    }

    if (!homeworkData.title) {
        alert("Please enter homework title.");
        return;
    }

    if (!homeworkData.description) {
        alert("Please enter homework description.");
        return;
    }

    if (!homeworkData.due_date) {
        alert("Please select due date.");
        return;
    }

    if (!homeworkData.created_by) {
        alert("Faculty information not found.");
        return;
    }

    try {

        let response;

        if (editingHomeworkId) {

            response = await fetch(
                `${API_BASE_URL}/homework/${editingHomeworkId}`,
                {
                    method: "PUT",
                    headers: {
                        "Content-Type": "application/json",
                        Authorization: `Bearer ${token}`
                    },
                    body: JSON.stringify({

                        title: homeworkData.title,
                        description: homeworkData.description,
                        due_date: homeworkData.due_date

                    })
                }
            );

        } else {

            response = await fetch(
                `${API_BASE_URL}/homework`,
                {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        Authorization: `Bearer ${token}`
                    },
                    body: JSON.stringify(homeworkData)
                }
            );

        }

        const result = await response.json();

        if (result.success) {

            alert(result.message);

            clearHomeworkForm();

            loadHomework();

        } else {

            alert(result.message);

        }

    } catch (error) {

        console.error("Save Homework Error:", error);

        alert("Unable to save homework.");

    }

}

// =====================================================
// Delete Homework
// =====================================================

async function deleteHomework(id) {

    const confirmDelete = confirm(
        "Are you sure you want to delete this homework?"
    );

    if (!confirmDelete) return;

    try {

        const response = await fetch(

            `${API_BASE_URL}/homework/${id}`,

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

            loadHomework();

        } else {

            alert(result.message);

        }

    } catch (error) {

        console.error("Delete Homework Error:", error);

        alert("Unable to delete homework.");

    }

}

// =====================================================
// Clear Form
// =====================================================

function clearHomeworkForm() {

    editingHomeworkId = null;

    classSelect.value = "";
    academicYearSelect.value = "";
    subjectSelect.value = "";

    titleInput.value = "";
    descriptionInput.value = "";
    dueDateInput.value = "";

    attachmentNameInput.value = "";
    attachmentPathInput.value = "";

    saveHomeworkBtn.textContent = "Save Homework";

}

// =====================================================
// Events
// =====================================================

saveHomeworkBtn.addEventListener(

    "click",

    saveHomework

);

clearHomeworkBtn.addEventListener(

    "click",

    clearHomeworkForm

);