// =====================================================
// announcements.js
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

const message =
    document.getElementById("message");

const priority =
    document.getElementById("priority");

const targetScope =
    document.getElementById("targetScope");

const saveAnnouncementBtn =
    document.getElementById("saveAnnouncementBtn");

const clearAnnouncementBtn =
    document.getElementById("clearAnnouncementBtn");

const announcementTableBody =
    document.getElementById("announcementTableBody");

const searchAnnouncement =
    document.getElementById("searchAnnouncement");

// =====================================================
// Global Variables
// =====================================================

let editingAnnouncementId = null;

const createdBy =
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

                    Authorization: `Bearer ${token}`

                }

            }

        );

        const result = await response.json();

        classSelect.innerHTML =
            `<option value="">Select Class</option>`;

        const classes = result.data || [];

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

                    Authorization: `Bearer ${token}`

                }

            }

        );

        const result = await response.json();

        academicYearSelect.innerHTML =
            `<option value="">Select Academic Year</option>`;

        const years = result.data || [];

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
// announcements.js
// Part 2
// Load | Search | Edit
// =====================================================

// =====================================================
// Load Announcements
// =====================================================

async function loadAnnouncements() {

    try {

        const response = await fetch(

            `${API_BASE_URL}/announcements`,

            {

                headers: {

                    Authorization: `Bearer ${token}`

                }

            }

        );

        const result = await response.json();

        announcementTableBody.innerHTML = "";

        if (!result.success || result.data.length === 0) {

            announcementTableBody.innerHTML = `

                <tr>

                    <td colspan="8" class="text-center">

                        No Announcements Available

                    </td>

                </tr>

            `;

            return;

        }

        result.data.forEach((item, index) => {

            announcementTableBody.innerHTML += `

                <tr>

                    <td>${index + 1}</td>

                    <td>${item.class_name}</td>

                    <td>${item.section}</td>

                    <td>${item.title}</td>

                    <td>${item.priority}</td>

                    <td>${item.target_scope}</td>

                    <td>${item.created_by}</td>

                    <td>

                        <button
                            class="btn btn-warning btn-sm"
                            onclick="editAnnouncement(${item.id})">

                            Edit

                        </button>

                        <button
                            class="btn btn-danger btn-sm"
                            onclick="deleteAnnouncement(${item.id})">

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

searchAnnouncement.addEventListener(

    "keyup",

    function () {

        const keyword =
            this.value.toLowerCase();

        const rows =
            announcementTableBody.querySelectorAll("tr");

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
// Edit Announcement
// =====================================================

async function editAnnouncement(id) {

    try {

        const response = await fetch(

            `${API_BASE_URL}/announcements/${id}`,

            {

                headers: {

                    Authorization: `Bearer ${token}`

                }

            }

        );

        const result = await response.json();

        const announcement = result.data;

        editingAnnouncementId = announcement.id;

        classSelect.value = announcement.class_id;
        academicYearSelect.value = announcement.academic_year_id;
        title.value = announcement.title;
        message.value = announcement.message;
        priority.value = announcement.priority;
        targetScope.value = announcement.target_scope;

        saveAnnouncementBtn.textContent =
            "Update Announcement";

    }

    catch (error) {

        console.error(error);

    }

}

document.addEventListener(
    "DOMContentLoaded",
    loadAnnouncements
);
// =====================================================
// announcements.js
// Part 3
// Save | Delete | Clear
// =====================================================

async function saveAnnouncement() {

    const announcementData = {

        class_id: classSelect.value,

        academic_year_id: academicYearSelect.value,

        title: title.value,

        message: message.value,

        priority: priority.value,

        created_by: createdBy,

        target_scope: targetScope.value

    };

    try {

        let response;

        if (editingAnnouncementId) {

            response = await fetch(

                `${API_BASE_URL}/announcements/${editingAnnouncementId}`,

                {

                    method: "PUT",

                    headers: {

                        "Content-Type": "application/json",

                        Authorization: `Bearer ${token}`

                    },

                    body: JSON.stringify({

                        title: announcementData.title,

                        message: announcementData.message,

                        priority: announcementData.priority,

                        target_scope: announcementData.target_scope

                    })

                }

            );

        }

        else {

            response = await fetch(

                `${API_BASE_URL}/announcements`,

                {

                    method: "POST",

                    headers: {

                        "Content-Type": "application/json",

                        Authorization: `Bearer ${token}`

                    },

                    body: JSON.stringify(announcementData)

                }

            );

        }

        const result = await response.json();

        alert(result.message);

        clearAnnouncementForm();

        loadAnnouncements();

    }

    catch (error) {

        console.error(error);

    }

}

// =====================================================
// Delete Announcement
// =====================================================

async function deleteAnnouncement(id) {

    if (!confirm("Delete Announcement?")) return;

    try {

        const response = await fetch(

            `${API_BASE_URL}/announcements/${id}`,

            {

                method: "DELETE",

                headers: {

                    Authorization: `Bearer ${token}`

                }

            }

        );

        const result = await response.json();

        alert(result.message);

        loadAnnouncements();

    }

    catch (error) {

        console.error(error);

    }

}

// =====================================================
// Clear Form
// =====================================================

function clearAnnouncementForm() {

    editingAnnouncementId = null;

    classSelect.value = "";
    academicYearSelect.value = "";
    title.value = "";
    message.value = "";
    priority.value = "";
    targetScope.value = "";

    saveAnnouncementBtn.textContent =
        "Save Announcement";

}

// =====================================================
// Events
// =====================================================

saveAnnouncementBtn.addEventListener(
    "click",
    saveAnnouncement
);

clearAnnouncementBtn.addEventListener(
    "click",
    clearAnnouncementForm
);