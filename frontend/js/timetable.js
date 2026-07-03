// =====================================================
// timetable.js
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

const classSelect =
    document.getElementById("classSelect");

const academicYearSelect =
    document.getElementById("academicYearSelect");

const title =
    document.getElementById("title");

const timetablePdf =
    document.getElementById("timetablePdf");

const remarks =
    document.getElementById("remarks");

const saveTimetableBtn =
    document.getElementById("saveTimetableBtn");

const clearTimetableBtn =
    document.getElementById("clearTimetableBtn");

const timetableTableBody =
    document.getElementById("timetableTableBody");

const searchTimetable =
    document.getElementById("searchTimetable");

// =====================================================
// Global Variables
// =====================================================

let editingTimetableId = null;

const uploadedBy =
    localStorage.getItem("faculty_id") ||
    localStorage.getItem("user_id");

// =====================================================
// Load Classes
// =====================================================

async function loadClasses() {

    try {

        const response = await fetch(

            `${API_BASE_URL}/classes`,

            {

                headers: {

                    Authorization:
                        `Bearer ${token}`

                }

            }

        );

        const result = await response.json();

        const classes = result.data || [];

        classSelect.innerHTML =
            `<option value="">Select Class</option>`;

        classes.forEach(cls => {

            classSelect.innerHTML += `

                <option value="${cls.id}">

                    ${cls.class_name}

                </option>

            `;

        });

    }

    catch (error) {

        console.error(error);

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

                    Authorization:
                        `Bearer ${token}`

                }

            }

        );

        const result = await response.json();

        const years = result.data || [];

        academicYearSelect.innerHTML =
            `<option value="">Select Academic Year</option>`;

        years.forEach(year => {

            academicYearSelect.innerHTML += `

                <option value="${year.id}">

                    ${year.year_name}

                </option>

            `;

        });

    }

    catch (error) {

        console.error(error);

    }

}

// =====================================================
// Initial Load
// =====================================================

document.addEventListener("DOMContentLoaded", () => {

    loadClasses();

    loadAcademicYears();

});
// =====================================================
// timetable.js
// Part 2
// Load | Search | Edit
// =====================================================

// =====================================================
// Load Timetables
// =====================================================

async function loadTimetables() {

    try {

        const response = await fetch(

            `${API_BASE_URL}/timetable`,

            {

                headers: {

                    Authorization:
                        `Bearer ${token}`

                }

            }

        );

        const result = await response.json();

        timetableTableBody.innerHTML = "";

        if (!result.success || result.data.length === 0) {

            timetableTableBody.innerHTML = `

                <tr>

                    <td colspan="8"
                        class="text-center">

                        No Timetables Available

                    </td>

                </tr>

            `;

            return;

        }

        result.data.forEach((item, index) => {

            timetableTableBody.innerHTML += `

                <tr>

                    <td>${index + 1}</td>

                    <td>${item.class_name}</td>

                    <td>${item.section}</td>

                    <td>${item.year_name}</td>

                    <td>${item.title}</td>

                    <td>

                        <a
                            href="${item.file_path}"
                            target="_blank"
                            class="btn btn-success btn-sm">

                            View PDF

                        </a>

                    </td>

                    <td>${item.uploaded_by_name}</td>

                    <td>

                        <button
                            class="btn btn-warning btn-sm"
                            onclick="editTimetable(${item.id})">

                            Edit

                        </button>

                        <button
                            class="btn btn-danger btn-sm"
                            onclick="deleteTimetable(${item.id})">

                            Delete

                        </button>

                    </td>

                </tr>

            `;

        });

    }

    catch (error) {

        console.error(error);

    }

}

// =====================================================
// Search
// =====================================================

searchTimetable.addEventListener(

    "keyup",

    function () {

        const keyword =
            this.value.toLowerCase();

        const rows =
            timetableTableBody.querySelectorAll("tr");

        rows.forEach(row => {

            row.style.display =

                row.innerText
                    .toLowerCase()
                    .includes(keyword)

                    ? ""

                    : "none";

        });

    }

);

// =====================================================
// Edit
// =====================================================

async function editTimetable(id) {

    try {

        const response = await fetch(

            `${API_BASE_URL}/timetable/${id}`,

            {

                headers: {

                    Authorization:
                        `Bearer ${token}`

                }

            }

        );

        const result = await response.json();

        const timetable = result.data;

        editingTimetableId = timetable.id;

        classSelect.value = timetable.class_id;
        academicYearSelect.value = timetable.academic_year_id;

        title.value = timetable.title;
        remarks.value = timetable.remarks;

        saveTimetableBtn.textContent =
            "Update Timetable";

    }

    catch (error) {

        console.error(error);

    }

}

document.addEventListener(
    "DOMContentLoaded",
    loadTimetables
);
// =====================================================
// timetable.js
// Part 3
// Save | Delete | Clear
// =====================================================

async function saveTimetable() {

    const timetableData = {

        class_id:
            classSelect.value,

        academic_year_id:
            academicYearSelect.value,

        title:
            title.value,

        file_name:
            timetablePdf.files.length
                ? timetablePdf.files[0].name
                : "",

        file_path:
            timetablePdf.files.length
                ? "uploads/" + timetablePdf.files[0].name
                : "",

        uploaded_by:
            uploadedBy,

        remarks:
            remarks.value

    };

    try {

        let response;

        if (editingTimetableId) {

            response = await fetch(

                `${API_BASE_URL}/timetable/${editingTimetableId}`,

                {

                    method: "PUT",

                    headers: {

                        "Content-Type":
                            "application/json",

                        Authorization:
                            `Bearer ${token}`

                    },

                    body: JSON.stringify({

                        title:
                            timetableData.title,

                        file_name:
                            timetableData.file_name,

                        file_path:
                            timetableData.file_path,

                        remarks:
                            timetableData.remarks

                    })

                }

            );

        }

        else {

            response = await fetch(

                `${API_BASE_URL}/timetable`,

                {

                    method: "POST",

                    headers: {

                        "Content-Type":
                            "application/json",

                        Authorization:
                            `Bearer ${token}`

                    },

                    body:
                        JSON.stringify(timetableData)

                }

            );

        }

        const result =
            await response.json();

        alert(result.message);

        clearTimetableForm();

        loadTimetables();

    }

    catch (error) {

        console.error(error);

    }

}

// =====================================================
// Delete
// =====================================================

async function deleteTimetable(id) {

    if (!confirm(
        "Delete Timetable?"
    )) return;

    try {

        const response = await fetch(

            `${API_BASE_URL}/timetable/${id}`,

            {

                method: "DELETE",

                headers: {

                    Authorization:
                        `Bearer ${token}`

                }

            }

        );

        const result =
            await response.json();

        alert(result.message);

        loadTimetables();

    }

    catch (error) {

        console.error(error);

    }

}

// =====================================================
// Clear Form
// =====================================================

function clearTimetableForm() {

    editingTimetableId = null;

    classSelect.value = "";
    academicYearSelect.value = "";
    title.value = "";
    timetablePdf.value = "";
    remarks.value = "";

    saveTimetableBtn.textContent =
        "Upload Timetable";

}

// =====================================================
// Events
// =====================================================

saveTimetableBtn.addEventListener(
    "click",
    saveTimetable
);

clearTimetableBtn.addEventListener(
    "click",
    clearTimetableForm
);