/* =====================================================
   GSR Universe ERP
   Faculty Management Module
   Part 1
===================================================== */

// ==========================================
// VARIABLES
// ==========================================

let facultyList = [];
let editFacultyId = null;

// ==========================================
// LOAD FACULTY
// ==========================================

async function loadFaculty() {

    try {

        const response = await fetch(

            API.faculty,

            {

                method: "GET",

                headers: {

                    Authorization: "Bearer " + TOKEN

                }

            }

        );

        const result = await response.json();

        if (!response.ok) {

            throw new Error(

                result.message ||

                "Unable to load faculty."

            );

        }

        facultyList = result.faculty || [];

        renderFacultyTable(facultyList);

    }

    catch (error) {

        console.error(error);

        alert(error.message);

    }

}

// ==========================================
// RENDER TABLE
// ==========================================

function renderFacultyTable(data) {

    const tbody = document.getElementById(

        "facultyTableBody"

    );

    if (!tbody) return;

    tbody.innerHTML = "";

    if (data.length === 0) {

        tbody.innerHTML = `

        <tr>

            <td colspan="9"

                class="text-center p-4">

                No Faculty Records Found

            </td>

        </tr>

        `;

        return;

    }

    data.forEach(f => {

        tbody.innerHTML += `

        <tr>

            <td>${f.id}</td>

            <td>${f.employee_id}</td>

            <td>${f.faculty_name}</td>

            <td>${f.email}</td>

            <td>${f.mobile || "-"}</td>

            <td>${f.subject || "-"}</td>

            <td>${f.role}</td>

            <td>

                <span class="badge ${

                    f.is_active

                    ? "bg-success"

                    : "bg-danger"

                }">

                    ${

                        f.is_active

                        ? "Active"

                        : "Inactive"

                    }

                </span>

            </td>

            <td>

                <button

                    class="btn btn-warning btn-sm"

                    onclick="editFaculty(${f.id})">

                    <i class="bi bi-pencil"></i>

                </button>

                <button

                    class="btn btn-danger btn-sm ms-2"

                    onclick="deleteFaculty(${f.id})">

                    <i class="bi bi-trash"></i>

                </button>

            </td>

        </tr>

        `;

    });

}

// ==========================================
// SEARCH
// ==========================================

function searchFaculty() {

    const keyword = document

        .getElementById("facultySearch")

        .value

        .toLowerCase()

        .trim();

    if (keyword === "") {

        renderFacultyTable(

            facultyList

        );

        return;

    }

    const filtered = facultyList.filter(f =>

        f.employee_id.toLowerCase().includes(keyword) ||

        f.faculty_name.toLowerCase().includes(keyword) ||

        f.email.toLowerCase().includes(keyword) ||

        (f.mobile || "").toLowerCase().includes(keyword)

    );

    renderFacultyTable(filtered);

}

console.log(

    "✅ Faculty Module Loaded"

);
