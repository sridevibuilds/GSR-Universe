// =====================================================
// progress.js
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

const studentSelect =
    document.getElementById("studentSelect");

const academicYearSelect =
    document.getElementById("academicYearSelect");

const examName =
    document.getElementById("examName");

const progressPdf =
    document.getElementById("progressPdf");

const saveProgressBtn =
    document.getElementById("saveProgressBtn");

const clearProgressBtn =
    document.getElementById("clearProgressBtn");

const progressTableBody =
    document.getElementById("progressTableBody");

const searchProgress =
    document.getElementById("searchProgress");

// =====================================================
// Global Variables
// =====================================================

let editingProgressId = null;

const uploadedBy =
    localStorage.getItem("faculty_id") ||
    localStorage.getItem("user_id");

// =====================================================
// Load Student Mapping
// =====================================================

async function loadStudents() {

    try {

        const response = await fetch(

            `${API_BASE_URL}/student-class-mapping`,

            {

                headers: {

                    Authorization:
                        `Bearer ${token}`

                }

            }

        );

        const result =
            await response.json();

        studentSelect.innerHTML =
            `<option value="">Select Student</option>`;

        const students =
            result.data || [];

        students.forEach(student => {

            studentSelect.innerHTML += `

                <option value="${student.id}">

                    ${student.student_name}

                    -

                    ${student.class_name}

                    ${student.section}

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

        const result =
            await response.json();

        academicYearSelect.innerHTML =
            `<option value="">Select Academic Year</option>`;

        const years =
            result.data || [];

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

document.addEventListener(

    "DOMContentLoaded",

    () => {

        loadStudents();

        loadAcademicYears();

    }

);
// =====================================================
// progress.js
// Part 2
// Load | Search | Edit
// =====================================================

// =====================================================
// Load Progress Cards
// =====================================================

async function loadProgressCards() {

    try {

        const response = await fetch(

            `${API_BASE_URL}/progress-cards`,

            {

                headers: {

                    Authorization:
                        `Bearer ${token}`

                }

            }

        );

        const result =
            await response.json();

        progressTableBody.innerHTML = "";

        if (!result.success || result.data.length === 0) {

            progressTableBody.innerHTML = `

                <tr>

                    <td colspan="6"
                        class="text-center">

                        No Progress Cards Available

                    </td>

                </tr>

            `;

            return;

        }

        result.data.forEach((card, index) => {

            progressTableBody.innerHTML += `

                <tr>

                    <td>${index + 1}</td>

                    <td>${card.student_name}</td>

                    <td>${card.year_name}</td>

                    <td>${card.file_name}</td>

                    <td>

                        <a

                            href="${card.file_path}"

                            target="_blank"

                            class="btn btn-success btn-sm">

                            View PDF

                        </a>

                    </td>

                    <td>

                        <button

                            class="btn btn-warning btn-sm"

                            onclick="editProgress(${card.id})">

                            Edit

                        </button>

                        <button

                            class="btn btn-danger btn-sm"

                            onclick="deleteProgress(${card.id})">

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

searchProgress.addEventListener(

    "keyup",

    function () {

        const keyword =
            this.value.toLowerCase();

        const rows =
            progressTableBody.querySelectorAll("tr");

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
// Edit Progress Card
// =====================================================

async function editProgress(id) {

    try {

        const response = await fetch(

            `${API_BASE_URL}/progress-cards/${id}`,

            {

                headers: {

                    Authorization:
                        `Bearer ${token}`

                }

            }

        );

        const result =
            await response.json();

        const card =
            result.data;

        editingProgressId =
            card.id;

        studentSelect.value =
            card.student_class_mapping_id;

        academicYearSelect.value =
            card.academic_year_id;

        saveProgressBtn.textContent =
            "Update Progress Card";

    }

    catch (error) {

        console.error(error);

    }

}

document.addEventListener(
    "DOMContentLoaded",
    loadProgressCards
);
// =====================================================
// progress.js
// Part 3
// Save | Delete | Clear
// =====================================================

async function saveProgressCard() {

    const progressData = {

        student_class_mapping_id:
            studentSelect.value,

        academic_year_id:
            academicYearSelect.value,

        uploaded_by:
            uploadedBy,

        file_name:
            progressPdf.files.length
                ? progressPdf.files[0].name
                : "",

        file_path:
            progressPdf.files.length
                ? "uploads/" + progressPdf.files[0].name
                : "",

        remarks:
            examName.value

    };

    try {

        let response;

        if (editingProgressId) {

            response = await fetch(

                `${API_BASE_URL}/progress-cards/${editingProgressId}`,

                {

                    method: "PUT",

                    headers: {

                        "Content-Type":
                            "application/json",

                        Authorization:
                            `Bearer ${token}`

                    },

                    body:
                        JSON.stringify({

                            file_name:
                                progressData.file_name,

                            file_path:
                                progressData.file_path,

                            remarks:
                                progressData.remarks

                        })

                }

            );

        }

        else {

            response = await fetch(

                `${API_BASE_URL}/progress-cards`,

                {

                    method: "POST",

                    headers: {

                        "Content-Type":
                            "application/json",

                        Authorization:
                            `Bearer ${token}`

                    },

                    body:
                        JSON.stringify(progressData)

                }

            );

        }

        const result =
            await response.json();

        alert(result.message);

        clearProgressForm();

        loadProgressCards();

    }

    catch (error) {

        console.error(error);

    }

}

// =====================================================
// Delete
// =====================================================

async function deleteProgress(id) {

    if (!confirm(
        "Delete Progress Card?"
    )) return;

    try {

        const response = await fetch(

            `${API_BASE_URL}/progress-cards/${id}`,

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

        loadProgressCards();

    }

    catch (error) {

        console.error(error);

    }

}

// =====================================================
// Clear
// =====================================================

function clearProgressForm() {

    editingProgressId = null;

    studentSelect.value = "";

    academicYearSelect.value = "";

    examName.value = "";

    progressPdf.value = "";

    saveProgressBtn.textContent =
        "Upload Progress Card";

}

// =====================================================
// Events
// =====================================================

saveProgressBtn.addEventListener(
    "click",
    saveProgressCard
);

clearProgressBtn.addEventListener(
    "click",
    clearProgressForm
);