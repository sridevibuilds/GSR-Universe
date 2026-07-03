// =====================================================
// fees.js
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

const totalFee =
    document.getElementById("totalFee");

const paidFee =
    document.getElementById("paidFee");

const pendingFee =
    document.getElementById("pendingFee");

const paymentStatus =
    document.getElementById("paymentStatus");

const paymentDate =
    document.getElementById("paymentDate");

const saveFeeBtn =
    document.getElementById("saveFeeBtn");

const clearFeeBtn =
    document.getElementById("clearFeeBtn");

const feeTableBody =
    document.getElementById("feeTableBody");

const searchFee =
    document.getElementById("searchFee");

// =====================================================
// Global Variable
// =====================================================

let editingFeeId = null;

// =====================================================
// Load Students
// =====================================================

async function loadStudents() {

    try {

        const response = await fetch(
            `${API_BASE_URL}/students`,
            {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            }
        );

        const result = await response.json();

        const students = result.data || [];

        studentSelect.innerHTML =
            `<option value="">Select Student</option>`;

        students.forEach(student => {

            studentSelect.innerHTML += `

                <option value="${student.id}">

                    ${student.student_name}

                </option>

            `;

        });

    } catch (error) {

        console.error(
            "Load Students Error:",
            error
        );

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

    } catch (error) {

        console.error(
            "Load Academic Years Error:",
            error
        );

    }

}

// =====================================================
// Initial Load
// =====================================================

document.addEventListener("DOMContentLoaded", () => {

    loadStudents();

    loadAcademicYears();

});
// =====================================================
// fees.js
// Part 2
// Load Fees | Search | Edit
// =====================================================

// =====================================================
// Load All Fee Records
// =====================================================

async function loadFees() {

    try {

        const response = await fetch(
            `${API_BASE_URL}/fees`,
            {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            }
        );

        const result = await response.json();

        feeTableBody.innerHTML = "";

        if (!result.success || result.data.length === 0) {

            feeTableBody.innerHTML = `

                <tr>

                    <td colspan="9"
                        class="text-center">

                        No Fee Records Available

                    </td>

                </tr>

            `;

            return;

        }

        result.data.forEach((fee, index) => {

            feeTableBody.innerHTML += `

                <tr>

                    <td>${index + 1}</td>

                    <td>${fee.student_name}</td>

                    <td>${fee.year_name}</td>

                    <td>${fee.total_fee}</td>

                    <td>${fee.paid_fee}</td>

                    <td>${fee.pending_fee}</td>

                    <td>${fee.payment_status}</td>

                    <td>${fee.payment_date}</td>

                    <td>

                        <button
                            class="btn btn-warning btn-sm"
                            onclick="editFee(${fee.id})">

                            Edit

                        </button>

                        <button
                            class="btn btn-danger btn-sm ms-1"
                            onclick="deleteFee(${fee.id})">

                            Delete

                        </button>

                    </td>

                </tr>

            `;

        });

    } catch (error) {

        console.error(
            "Load Fees Error:",
            error
        );

    }

}

// =====================================================
// Search Fee
// =====================================================

searchFee.addEventListener("keyup", function () {

    const keyword =
        this.value.toLowerCase();

    const rows =
        feeTableBody.querySelectorAll("tr");

    rows.forEach(row => {

        row.style.display =
            row.innerText.toLowerCase().includes(keyword)
                ? ""
                : "none";

    });

});

// =====================================================
// Edit Fee
// =====================================================

async function editFee(id) {

    try {

        const response = await fetch(

            `${API_BASE_URL}/fees/${id}`,

            {

                headers: {

                    Authorization:
                        `Bearer ${token}`

                }

            }

        );

        const result =
            await response.json();

        if (!result.success) {

            alert("Unable to load fee.");

            return;

        }

        const fee =
            result.data;

        editingFeeId =
            fee.id;

        studentSelect.value =
            fee.student_id;

        academicYearSelect.value =
            fee.academic_year_id;

        totalFee.value =
            fee.total_fee;

        paidFee.value =
            fee.paid_fee;

        pendingFee.value =
            fee.pending_fee;

        paymentStatus.value =
            fee.payment_status;

        paymentDate.value =
            fee.payment_date
                ? fee.payment_date.split("T")[0]
                : "";

        saveFeeBtn.textContent =
            "Update Fee";

    } catch (error) {

        console.error(error);

    }

}

document.addEventListener(
    "DOMContentLoaded",
    loadFees
);
// =====================================================
// fees.js
// Part 3
// Create | Update | Delete | Clear
// =====================================================

async function saveFee() {

    const feeData = {

        student_id:
            studentSelect.value,

        academic_year_id:
            academicYearSelect.value,

        total_fee:
            totalFee.value,

        paid_fee:
            paidFee.value,

        pending_fee:
            pendingFee.value,

        payment_status:
            paymentStatus.value,

        payment_date:
            paymentDate.value

    };

    try {

        let response;

        if (editingFeeId) {

            response = await fetch(

                `${API_BASE_URL}/fees/${editingFeeId}`,

                {

                    method: "PUT",

                    headers: {

                        "Content-Type":
                            "application/json",

                        Authorization:
                            `Bearer ${token}`

                    },

                    body:
                        JSON.stringify(feeData)

                }

            );

        } else {

            response = await fetch(

                `${API_BASE_URL}/fees`,

                {

                    method: "POST",

                    headers: {

                        "Content-Type":
                            "application/json",

                        Authorization:
                            `Bearer ${token}`

                    },

                    body:
                        JSON.stringify(feeData)

                }

            );

        }

        const result =
            await response.json();

        alert(result.message);

        clearFeeForm();

        loadFees();

    } catch (error) {

        console.error(error);

        alert("Unable to save fee.");

    }

}

// =====================================================
// Delete Fee
// =====================================================

async function deleteFee(id) {

    if (!confirm("Delete this fee record?")) {

        return;

    }

    try {

        const response = await fetch(

            `${API_BASE_URL}/fees/${id}`,

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

        loadFees();

    } catch (error) {

        console.error(error);

    }

}

// =====================================================
// Clear Form
// =====================================================

function clearFeeForm() {

    editingFeeId = null;

    studentSelect.value = "";
    academicYearSelect.value = "";

    totalFee.value = "";
    paidFee.value = "";
    pendingFee.value = "";

    paymentStatus.value = "";
    paymentDate.value = "";

    saveFeeBtn.textContent =
        "Save Fee Details";

}

// =====================================================
// Events
// =====================================================

saveFeeBtn.addEventListener(
    "click",
    saveFee
);

clearFeeBtn.addEventListener(
    "click",
    clearFeeForm
);