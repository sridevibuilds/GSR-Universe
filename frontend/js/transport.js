// =====================================================
// transport.js
// Part 1
// Initialization & Load Students
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

const busNumber =
    document.getElementById("busNumber");

const routeName =
    document.getElementById("routeName");

const pickupPoint =
    document.getElementById("pickupPoint");

const dropPoint =
    document.getElementById("dropPoint");

const driverName =
    document.getElementById("driverName");

const driverMobile =
    document.getElementById("driverMobile");

const attendantName =
    document.getElementById("attendantName");

const attendantMobile =
    document.getElementById("attendantMobile");

const remarks =
    document.getElementById("remarks");

const saveTransportBtn =
    document.getElementById("saveTransportBtn");

const clearTransportBtn =
    document.getElementById("clearTransportBtn");

const transportTableBody =
    document.getElementById("transportTableBody");

const searchTransport =
    document.getElementById("searchTransport");

// =====================================================
// Global Variables
// =====================================================

let editingTransportId = null;

const updatedBy =
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
// Initial Load
// =====================================================

document.addEventListener(

    "DOMContentLoaded",

    () => {

        loadStudents();

        loadTransport();

    }

);// =====================================================
// transport.js
// Part 2
// Load | Search | Edit
// =====================================================

// =====================================================
// Load Transport Records
// =====================================================

async function loadTransport() {

    try {

        const response = await fetch(

            `${API_BASE_URL}/transport`,

            {

                headers: {

                    Authorization:
                        `Bearer ${token}`

                }

            }

        );

        const result =
            await response.json();

        transportTableBody.innerHTML = "";

        if (!result.success || result.data.length === 0) {

            transportTableBody.innerHTML = `

                <tr>

                    <td colspan="8" class="text-center">

                        No Transport Records Available

                    </td>

                </tr>

            `;

            return;

        }

        result.data.forEach((transport, index) => {

            transportTableBody.innerHTML += `

                <tr>

                    <td>${index + 1}</td>

                    <td>${transport.student_name}</td>

                    <td>${transport.class_name} ${transport.section}</td>

                    <td>${transport.bus_number}</td>

                    <td>${transport.route_name}</td>

                    <td>${transport.driver_name}</td>

                    <td>${transport.driver_mobile}</td>

                    <td>

                        <button
                            class="btn btn-warning btn-sm"
                            onclick="editTransport(${transport.id})">

                            Edit

                        </button>

                        <button
                            class="btn btn-danger btn-sm"
                            onclick="deleteTransport(${transport.id})">

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

searchTransport.addEventListener(

    "keyup",

    function () {

        const keyword =
            this.value.toLowerCase();

        const rows =
            transportTableBody.querySelectorAll("tr");

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

async function editTransport(id) {

    try {

        const response = await fetch(

            `${API_BASE_URL}/transport/${id}`,

            {

                headers: {

                    Authorization:
                        `Bearer ${token}`

                }

            }

        );

        const result =
            await response.json();

        const transport =
            result.data;

        editingTransportId =
            transport.id;

        studentSelect.value =
            transport.student_class_mapping_id;

        busNumber.value =
            transport.bus_number;

        routeName.value =
            transport.route_name;

        pickupPoint.value =
            transport.pickup_point;

        dropPoint.value =
            transport.drop_point;

        driverName.value =
            transport.driver_name;

        driverMobile.value =
            transport.driver_mobile;

        attendantName.value =
            transport.attendant_name;

        attendantMobile.value =
            transport.attendant_mobile;

        remarks.value =
            transport.remarks;

        saveTransportBtn.textContent =
            "Update Transport";

    }

    catch (error) {

        console.error(error);

    }

}
// =====================================================
// transport.js
// Part 3
// Save | Delete | Clear
// =====================================================

async function saveTransport() {

    const transportData = {

        student_class_mapping_id:
            studentSelect.value,

        bus_number:
            busNumber.value,

        route_name:
            routeName.value,

        pickup_point:
            pickupPoint.value,

        drop_point:
            dropPoint.value,

        driver_name:
            driverName.value,

        driver_mobile:
            driverMobile.value,

        attendant_name:
            attendantName.value,

        attendant_mobile:
            attendantMobile.value,

        remarks:
            remarks.value,

        updated_by:
            updatedBy

    };

    try {

        let response;

        if (editingTransportId) {

            response = await fetch(

                `${API_BASE_URL}/transport/${editingTransportId}`,

                {

                    method: "PUT",

                    headers: {

                        "Content-Type":
                            "application/json",

                        Authorization:
                            `Bearer ${token}`

                    },

                    body: JSON.stringify({

                        bus_number:
                            transportData.bus_number,

                        route_name:
                            transportData.route_name,

                        pickup_point:
                            transportData.pickup_point,

                        drop_point:
                            transportData.drop_point,

                        driver_name:
                            transportData.driver_name,

                        driver_mobile:
                            transportData.driver_mobile,

                        attendant_name:
                            transportData.attendant_name,

                        attendant_mobile:
                            transportData.attendant_mobile,

                        remarks:
                            transportData.remarks

                    })

                }

            );

        }

        else {

            response = await fetch(

                `${API_BASE_URL}/transport`,

                {

                    method: "POST",

                    headers: {

                        "Content-Type":
                            "application/json",

                        Authorization:
                            `Bearer ${token}`

                    },

                    body:
                        JSON.stringify(transportData)

                }

            );

        }

        const result =
            await response.json();

        alert(result.message);

        clearTransportForm();

        loadTransport();

    }

    catch (error) {

        console.error(error);

    }

}

// =====================================================
// Delete
// =====================================================

async function deleteTransport(id) {

    if (!confirm("Delete Transport Record?")) return;

    try {

        const response = await fetch(

            `${API_BASE_URL}/transport/${id}`,

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

        loadTransport();

    }

    catch (error) {

        console.error(error);

    }

}

// =====================================================
// Clear Form
// =====================================================

function clearTransportForm() {

    editingTransportId = null;

    studentSelect.value = "";
    busNumber.value = "";
    routeName.value = "";
    pickupPoint.value = "";
    dropPoint.value = "";
    driverName.value = "";
    driverMobile.value = "";
    attendantName.value = "";
    attendantMobile.value = "";
    remarks.value = "";

    saveTransportBtn.textContent =
        "Save Transport";

}

// =====================================================
// Events
// =====================================================

saveTransportBtn.addEventListener(
    "click",
    saveTransport
);

clearTransportBtn.addEventListener(
    "click",
    clearTransportForm
);