// =====================================================
// noticeboard.js
// Part 1
// Initialization & DOM
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

const title =
    document.getElementById("title");

const description =
    document.getElementById("description");

const noticeAttachment =
    document.getElementById("noticeAttachment");

const targetScope =
    document.getElementById("targetScope");

const saveNoticeBtn =
    document.getElementById("saveNoticeBtn");

const clearNoticeBtn =
    document.getElementById("clearNoticeBtn");

const noticeTableBody =
    document.getElementById("noticeTableBody");

const searchNotice =
    document.getElementById("searchNotice");

// =====================================================
// Global Variables
// =====================================================

let editingNoticeId = null;

const createdBy =
    localStorage.getItem("faculty_id") ||
    localStorage.getItem("user_id");

// =====================================================
// Initial Load
// =====================================================

document.addEventListener(

    "DOMContentLoaded",

    () => {

        loadNotices();

    }

);
// =====================================================
// noticeboard.js
// Part 2
// Load | Search | Edit
// =====================================================

// =====================================================
// Load Notices
// =====================================================

async function loadNotices() {

    try {

        const response = await fetch(

            `${API_BASE_URL}/notice-board`,

            {

                headers: {

                    Authorization:
                        `Bearer ${token}`

                }

            }

        );

        const result =
            await response.json();

        noticeTableBody.innerHTML = "";

        if (!result.success || result.data.length === 0) {

            noticeTableBody.innerHTML = `

                <tr>

                    <td colspan="8" class="text-center">

                        No Notices Available

                    </td>

                </tr>

            `;

            return;

        }

        result.data.forEach((notice, index) => {

            noticeTableBody.innerHTML += `

                <tr>

                    <td>${index + 1}</td>

                    <td>${notice.title}</td>

                    <td>${notice.description}</td>

                    <td>

                        <a
                            href="${notice.attachment_path}"
                            target="_blank"
                            class="btn btn-success btn-sm">

                            View

                        </a>

                    </td>

                    <td>${notice.target_scope}</td>

                    <td>${notice.created_by_name}</td>

                    <td>${notice.created_at}</td>

                    <td>

                        <button
                            class="btn btn-warning btn-sm"
                            onclick="editNotice(${notice.id})">

                            Edit

                        </button>

                        <button
                            class="btn btn-danger btn-sm"
                            onclick="deleteNotice(${notice.id})">

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
// Search Notice
// =====================================================

searchNotice.addEventListener(

    "keyup",

    function () {

        const keyword =
            this.value.toLowerCase();

        const rows =
            noticeTableBody.querySelectorAll("tr");

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
// Edit Notice
// =====================================================

async function editNotice(id) {

    try {

        const response = await fetch(

            `${API_BASE_URL}/notice-board/${id}`,

            {

                headers: {

                    Authorization:
                        `Bearer ${token}`

                }

            }

        );

        const result =
            await response.json();

        const notice =
            result.data;

        editingNoticeId =
            notice.id;

        title.value =
            notice.title;

        description.value =
            notice.description;

        targetScope.value =
            notice.target_scope;

        saveNoticeBtn.textContent =
            "Update Notice";

    }

    catch (error) {

        console.error(error);

    }

}
// =====================================================
// noticeboard.js
// Part 3
// Save | Delete | Clear
// =====================================================

async function saveNotice() {

    const noticeData = {

        title:
            title.value,

        description:
            description.value,

        attachment_name:
            noticeAttachment.files.length
                ? noticeAttachment.files[0].name
                : "",

        attachment_path:
            noticeAttachment.files.length
                ? "uploads/" +
                  noticeAttachment.files[0].name
                : "",

        created_by:
            createdBy,

        target_scope:
            targetScope.value

    };

    try {

        let response;

        if (editingNoticeId) {

            response = await fetch(

                `${API_BASE_URL}/notice-board/${editingNoticeId}`,

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
                            noticeData.title,

                        description:
                            noticeData.description,

                        attachment_name:
                            noticeData.attachment_name,

                        attachment_path:
                            noticeData.attachment_path,

                        target_scope:
                            noticeData.target_scope

                    })

                }

            );

        }

        else {

            response = await fetch(

                `${API_BASE_URL}/notice-board`,

                {

                    method: "POST",

                    headers: {

                        "Content-Type":
                            "application/json",

                        Authorization:
                            `Bearer ${token}`

                    },

                    body:
                        JSON.stringify(noticeData)

                }

            );

        }

        const result =
            await response.json();

        alert(result.message);

        clearNoticeForm();

        loadNotices();

    }

    catch (error) {

        console.error(error);

    }

}

// =====================================================
// Delete Notice
// =====================================================

async function deleteNotice(id) {

    if (!confirm("Delete Notice?")) return;

    try {

        const response = await fetch(

            `${API_BASE_URL}/notice-board/${id}`,

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

        loadNotices();

    }

    catch (error) {

        console.error(error);

    }

}

// =====================================================
// Clear Form
// =====================================================

function clearNoticeForm() {

    editingNoticeId = null;

    title.value = "";
    description.value = "";
    noticeAttachment.value = "";
    targetScope.value = "";

    saveNoticeBtn.textContent =
        "Save Notice";

}

// =====================================================
// Events
// =====================================================

saveNoticeBtn.addEventListener(
    "click",
    saveNotice
);

clearNoticeBtn.addEventListener(
    "click",
    clearNoticeForm
);