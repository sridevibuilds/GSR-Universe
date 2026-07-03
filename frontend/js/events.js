// =====================================================
// events.js
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

const eventDate =
    document.getElementById("eventDate");

const eventTime =
    document.getElementById("eventTime");

const venue =
    document.getElementById("venue");

const eventAttachment =
    document.getElementById("eventAttachment");

const eventStatus =
    document.getElementById("eventStatus");

const targetScope =
    document.getElementById("targetScope");

const saveEventBtn =
    document.getElementById("saveEventBtn");

const clearEventBtn =
    document.getElementById("clearEventBtn");

const eventTableBody =
    document.getElementById("eventTableBody");

const searchEvent =
    document.getElementById("searchEvent");

// =====================================================
// Global Variables
// =====================================================

let editingEventId = null;

const createdBy =
    localStorage.getItem("faculty_id") ||
    localStorage.getItem("user_id");

// =====================================================
// Initial Load
// =====================================================

document.addEventListener(

    "DOMContentLoaded",

    () => {

        loadEvents();

    }

);
// =====================================================
// events.js
// Part 2
// Load | Search | Edit
// =====================================================

// =====================================================
// Load Events
// =====================================================

async function loadEvents() {

    try {

        const response = await fetch(

            `${API_BASE_URL}/events`,

            {

                headers: {

                    Authorization:
                        `Bearer ${token}`

                }

            }

        );

        const result =
            await response.json();

        eventTableBody.innerHTML = "";

        if (!result.success || result.data.length === 0) {

            eventTableBody.innerHTML = `

                <tr>

                    <td colspan="9" class="text-center">

                        No Events Available

                    </td>

                </tr>

            `;

            return;

        }

        result.data.forEach((event, index) => {

            eventTableBody.innerHTML += `

                <tr>

                    <td>${index + 1}</td>

                    <td>${event.title}</td>

                    <td>${event.event_date}</td>

                    <td>${event.event_time}</td>

                    <td>${event.venue}</td>

                    <td>${event.event_status}</td>

                    <td>${event.target_scope}</td>

                    <td>${event.created_by_name}</td>

                    <td>

                        <button
                            class="btn btn-warning btn-sm"
                            onclick="editEvent(${event.id})">

                            Edit

                        </button>

                        <button
                            class="btn btn-danger btn-sm"
                            onclick="deleteEvent(${event.id})">

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

searchEvent.addEventListener(

    "keyup",

    function () {

        const keyword =
            this.value.toLowerCase();

        const rows =
            eventTableBody.querySelectorAll("tr");

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
// Edit Event
// =====================================================

async function editEvent(id) {

    try {

        const response = await fetch(

            `${API_BASE_URL}/events/${id}`,

            {

                headers: {

                    Authorization:
                        `Bearer ${token}`

                }

            }

        );

        const result =
            await response.json();

        const event =
            result.data;

        editingEventId =
            event.id;

        title.value = event.title;
        description.value = event.description;
        eventDate.value = event.event_date;
        eventTime.value = event.event_time;
        venue.value = event.venue;
        eventStatus.value = event.event_status;
        targetScope.value = event.target_scope;

        saveEventBtn.textContent =
            "Update Event";

    }

    catch (error) {

        console.error(error);

    }

}
// =====================================================
// events.js
// Part 3
// Save | Delete | Clear
// =====================================================

async function saveEvent() {

    const eventData = {

        title:
            title.value,

        description:
            description.value,

        event_date:
            eventDate.value,

        event_time:
            eventTime.value,

        venue:
            venue.value,

        attachment_name:
            eventAttachment.files.length
                ? eventAttachment.files[0].name
                : "",

        attachment_path:
            eventAttachment.files.length
                ? "uploads/" +
                  eventAttachment.files[0].name
                : "",

        created_by:
            createdBy,

        event_status:
            eventStatus.value,

        target_scope:
            targetScope.value

    };

    try {

        let response;

        if (editingEventId) {

            response = await fetch(

                `${API_BASE_URL}/events/${editingEventId}`,

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
                            eventData.title,

                        description:
                            eventData.description,

                        event_date:
                            eventData.event_date,

                        event_time:
                            eventData.event_time,

                        venue:
                            eventData.venue,

                        event_status:
                            eventData.event_status,

                        target_scope:
                            eventData.target_scope

                    })

                }

            );

        } else {

            response = await fetch(

                `${API_BASE_URL}/events`,

                {

                    method: "POST",

                    headers: {

                        "Content-Type":
                            "application/json",

                        Authorization:
                            `Bearer ${token}`

                    },

                    body:
                        JSON.stringify(eventData)

                }

            );

        }

        const result =
            await response.json();

        alert(result.message);

        clearEventForm();

        loadEvents();

    }

    catch (error) {

        console.error(error);

    }

}

// =====================================================
// Delete Event
// =====================================================

async function deleteEvent(id) {

    if (!confirm("Delete Event?")) return;

    try {

        const response = await fetch(

            `${API_BASE_URL}/events/${id}`,

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

        loadEvents();

    }

    catch (error) {

        console.error(error);

    }

}

// =====================================================
// Clear Form
// =====================================================

function clearEventForm() {

    editingEventId = null;

    title.value = "";
    description.value = "";
    eventDate.value = "";
    eventTime.value = "";
    venue.value = "";
    eventAttachment.value = "";
    eventStatus.value = "";
    targetScope.value = "";

    saveEventBtn.textContent =
        "Save Event";

}

// =====================================================
// Events
// =====================================================

saveEventBtn.addEventListener(
    "click",
    saveEvent
);

clearEventBtn.addEventListener(
    "click",
    clearEventForm
);