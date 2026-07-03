// =====================================================
// holidays.js
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

const holidayName =
    document.getElementById("holidayName");

const description =
    document.getElementById("description");

const startDate =
    document.getElementById("startDate");

const endDate =
    document.getElementById("endDate");

const holidayType =
    document.getElementById("holidayType");

const targetScope =
    document.getElementById("targetScope");

const saveHolidayBtn =
    document.getElementById("saveHolidayBtn");

const clearHolidayBtn =
    document.getElementById("clearHolidayBtn");

const holidayTableBody =
    document.getElementById("holidayTableBody");

const searchHoliday =
    document.getElementById("searchHoliday");

// =====================================================
// Global Variables
// =====================================================

let editingHolidayId = null;

const createdBy =
    localStorage.getItem("faculty_id") ||
    localStorage.getItem("user_id");

// =====================================================
// Initial Load
// =====================================================

document.addEventListener(

    "DOMContentLoaded",

    () => {

        loadHolidays();

    }

);
// =====================================================
// holidays.js
// Part 2
// Load | Search | Edit
// =====================================================

// =====================================================
// Load Holidays
// =====================================================

async function loadHolidays() {

    try {

        const response = await fetch(

            `${API_BASE_URL}/holidays`,

            {

                headers: {

                    Authorization:
                        `Bearer ${token}`

                }

            }

        );

        const result =
            await response.json();

        holidayTableBody.innerHTML = "";

        if (!result.success || result.data.length === 0) {

            holidayTableBody.innerHTML = `

                <tr>

                    <td colspan="8" class="text-center">

                        No Holidays Available

                    </td>

                </tr>

            `;

            return;

        }

        result.data.forEach((holiday, index) => {

            holidayTableBody.innerHTML += `

                <tr>

                    <td>${index + 1}</td>

                    <td>${holiday.holiday_name}</td>

                    <td>${holiday.holiday_type}</td>

                    <td>${holiday.start_date}</td>

                    <td>${holiday.end_date}</td>

                    <td>${holiday.target_scope}</td>

                    <td>${holiday.created_by_name}</td>

                    <td>

                        <button
                            class="btn btn-warning btn-sm"
                            onclick="editHoliday(${holiday.id})">

                            Edit

                        </button>

                        <button
                            class="btn btn-danger btn-sm"
                            onclick="deleteHoliday(${holiday.id})">

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

searchHoliday.addEventListener(

    "keyup",

    function () {

        const keyword =
            this.value.toLowerCase();

        const rows =
            holidayTableBody.querySelectorAll("tr");

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
// Edit Holiday
// =====================================================

async function editHoliday(id) {

    try {

        const response = await fetch(

            `${API_BASE_URL}/holidays/${id}`,

            {

                headers: {

                    Authorization:
                        `Bearer ${token}`

                }

            }

        );

        const result =
            await response.json();

        const holiday =
            result.data;

        editingHolidayId =
            holiday.id;

        holidayName.value =
            holiday.holiday_name;

        description.value =
            holiday.description;

        startDate.value =
            holiday.start_date;

        endDate.value =
            holiday.end_date;

        holidayType.value =
            holiday.holiday_type;

        targetScope.value =
            holiday.target_scope;

        saveHolidayBtn.textContent =
            "Update Holiday";

    }

    catch (error) {

        console.error(error);

    }

}
// =====================================================
// holidays.js
// Part 3
// Save | Delete | Clear
// =====================================================

async function saveHoliday() {

    const holidayData = {

        holiday_name:
            holidayName.value,

        description:
            description.value,

        start_date:
            startDate.value,

        end_date:
            endDate.value,

        holiday_type:
            holidayType.value,

        created_by:
            createdBy,

        target_scope:
            targetScope.value

    };

    try {

        let response;

        if (editingHolidayId) {

            response = await fetch(

                `${API_BASE_URL}/holidays/${editingHolidayId}`,

                {

                    method: "PUT",

                    headers: {

                        "Content-Type":
                            "application/json",

                        Authorization:
                            `Bearer ${token}`

                    },

                    body: JSON.stringify({

                        holiday_name:
                            holidayData.holiday_name,

                        description:
                            holidayData.description,

                        start_date:
                            holidayData.start_date,

                        end_date:
                            holidayData.end_date,

                        holiday_type:
                            holidayData.holiday_type,

                        target_scope:
                            holidayData.target_scope

                    })

                }

            );

        } else {

            response = await fetch(

                `${API_BASE_URL}/holidays`,

                {

                    method: "POST",

                    headers: {

                        "Content-Type":
                            "application/json",

                        Authorization:
                            `Bearer ${token}`

                    },

                    body:
                        JSON.stringify(holidayData)

                }

            );

        }

        const result =
            await response.json();

        alert(result.message);

        clearHolidayForm();

        loadHolidays();

    }

    catch (error) {

        console.error(error);

    }

}

// =====================================================
// Delete Holiday
// =====================================================

async function deleteHoliday(id) {

    if (!confirm("Delete Holiday?")) return;

    try {

        const response = await fetch(

            `${API_BASE_URL}/holidays/${id}`,

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

        loadHolidays();

    }

    catch (error) {

        console.error(error);

    }

}

// =====================================================
// Clear Form
// =====================================================

function clearHolidayForm() {

    editingHolidayId = null;

    holidayName.value = "";
    description.value = "";
    startDate.value = "";
    endDate.value = "";
    holidayType.value = "";
    targetScope.value = "";

    saveHolidayBtn.textContent =
        "Save Holiday";

}

// =====================================================
// Events
// =====================================================

saveHolidayBtn.addEventListener(
    "click",
    saveHoliday
);

clearHolidayBtn.addEventListener(
    "click",
    clearHolidayForm
);