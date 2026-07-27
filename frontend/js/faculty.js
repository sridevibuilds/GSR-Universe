/* =====================================================
   GSR Universe ERP
   Faculty Management
===================================================== */

(() => {

"use strict";

// =====================================================
// LOCAL VARIABLES
// =====================================================

const facultyToken =
    localStorage.getItem("token");

const facultyAPI =
    API.faculty;

let facultyList = [];

let filteredFaculty = [];

let editFacultyId = null;

let selectedFacultyId = null;

// =====================================================
// INITIALIZE MODULE
// =====================================================

function initializeFacultyModule() {

    loadFaculty();

}

// =====================================================
// LOAD FACULTY
// =====================================================
async function loadFaculty() {

    try {

        const response = await fetch(

            facultyAPI,

            {

                method: "GET",

                headers: {

                    Authorization:

                        "Bearer " + facultyToken

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

        filteredFaculty = [...facultyList];

        updateDashboardCards();

        renderFacultyTable(filteredFaculty);

    }

    catch (error) {

        console.error(error);

        showToast(

            error.message ||

            "Unable to load faculty.",

            "danger"

        );

    }

}

// =====================================================
// UPDATE DASHBOARD CARDS
// =====================================================

function updateDashboardCards() {

    const total = facultyList.length;

    const active = facultyList.filter(

        faculty => faculty.is_active

    ).length;

    const disabled = total - active;

    const totalElement =

        document.getElementById(

            "totalFaculty"

        );

    const activeElement =

        document.getElementById(

            "activeFaculty"

        );

    const disabledElement =

        document.getElementById(

            "disabledFaculty"

        );

    if (totalElement)

        totalElement.textContent = total;

    if (activeElement)

        activeElement.textContent = active;

    if (disabledElement)

        disabledElement.textContent = disabled;

}

// =====================================================
// UPDATE FACULTY COUNT
// =====================================================

function updateFacultyCount() {

    const badge = document.getElementById(

        "facultyCount"

    );

    if (!badge) return;

    badge.textContent =

        filteredFaculty.length +

        " Faculty";

}
// =====================================================
// RENDER FACULTY TABLE
// =====================================================

function renderFacultyTable(data) {

    const tbody = document.getElementById(

        "facultyTableBody"

    );

    if (!tbody) return;

    tbody.innerHTML = "";

    if (data.length === 0) {

        tbody.innerHTML = `

<tr>

<td colspan="8" class="text-center py-5">

<i class="bi bi-people-fill"

style="font-size:60px;color:#CBD5E1;"></i>

<h5 class="mt-3">

No Faculty Found

</h5>

<p class="text-muted">

There are no faculty records.

</p>

</td>

</tr>

`;

        updateFacultyCount();

        return;

    }

    data.forEach(faculty => {

        tbody.innerHTML += `

<tr>

<td>

<img

src="assets/images/avatar.png"

class="faculty-photo"

alt="Faculty">

</td>

<td class="employee-id">

${faculty.employee_id}

</td>

<td>

<div class="faculty-name">

${faculty.faculty_name}

</div>

<div class="faculty-email">

${faculty.email}

</div>

</td>

<td>

${faculty.subject || "-"}

</td>

<td>

${faculty.mobile || "-"}

</td>

<td>

<span class="${faculty.is_active ? "status-active" : "status-disabled"}">

${faculty.is_active ? "Active" : "Disabled"}

</span>

</td>

<td>

<div class="action-buttons">

<button

class="btn btn-warning"

title="Edit"

onclick="editFaculty(${faculty.id})">

<i class="bi bi-pencil-square"></i>

</button>

<button

class="btn ${faculty.is_active ? "btn-secondary" : "btn-success"}"

title="${faculty.is_active ? "Disable" : "Enable"}"

onclick="toggleFacultyStatus(${faculty.id}, ${faculty.is_active})">

<i class="bi ${faculty.is_active ? "bi-person-lock" : "bi-person-check-fill"}"></i>

</button>

<button

class="btn btn-danger"

title="Delete"

onclick="deleteFaculty(${faculty.id})">

<i class="bi bi-trash-fill"></i>

</button>

</div>

</td>

</tr>

`;

    });

    updateFacultyCount();

}

// =====================================================
// SEARCH FACULTY
// =====================================================

function searchFaculty() {

    const keyword = document

        .getElementById(

            "facultySearch"

        )

        .value

        .trim()

        .toLowerCase();

    filteredFaculty = facultyList.filter(

        faculty =>

            (faculty.employee_id || "")

                .toLowerCase()

                .includes(keyword)

            ||

            (faculty.faculty_name || "")

                .toLowerCase()

                .includes(keyword)

            ||

            (faculty.email || "")

                .toLowerCase()

                .includes(keyword)

            ||

            (faculty.mobile || "")

                .toLowerCase()

                .includes(keyword)

            ||

            (faculty.subject || "")

                .toLowerCase()

                .includes(keyword)

    );

    renderFacultyTable(filteredFaculty);

}

// =====================================================
// FILTER FACULTY
// =====================================================

function filterFaculty() {

    const status = document

        .getElementById(

            "facultyStatusFilter"

        )

        .value;

    if (status === "active") {

        filteredFaculty = facultyList.filter(

            faculty => faculty.is_active

        );

    }

    else if (status === "inactive") {

        filteredFaculty = facultyList.filter(

            faculty => !faculty.is_active

        );

    }

    else {

        filteredFaculty = [...facultyList];

    }

    renderFacultyTable(filteredFaculty);

}
// =====================================================
// OPEN ADD FACULTY MODAL
// =====================================================

function openFacultyModal() {

    editFacultyId = null;

    document.getElementById("facultyForm").reset();

    document.getElementById("facultyModalTitle").innerHTML =
        '<i class="bi bi-person-plus-fill me-2"></i>Add Faculty';

    document.getElementById("saveFacultyBtn")
        .classList.remove("d-none");

    document.getElementById("updateFacultyBtn")
        .classList.add("d-none");

    const modal = new bootstrap.Modal(

        document.getElementById("facultyModal")

    );

    modal.show();

}

// =====================================================
// SAVE FACULTY
// =====================================================

async function saveFaculty() {

    const password =
        document.getElementById("facultyPassword").value.trim();

    const confirmPassword =
        document.getElementById("facultyConfirmPassword").value.trim();

    if (password !== confirmPassword) {

        showToast(

            "Passwords do not match.",

            "danger"

        );

        return;

    }

    const data = {

        employee_id:
            document.getElementById("employeeId").value.trim(),

        faculty_name:
            document.getElementById("facultyName").value.trim(),

        email:
            document.getElementById("facultyEmail").value.trim(),

        password,

        mobile:
            document.getElementById("facultyMobile").value.trim(),

        subject:
            document.getElementById("facultySubject").value.trim(),

        role:
            document.getElementById("facultyRole").value

    };

    try {

        const response = await fetch(

            facultyAPI + "/create",

            {

                method: "POST",

                headers: {

                    "Content-Type": "application/json",

                    Authorization:

                        "Bearer " + facultyToken

                },

                body: JSON.stringify(data)

            }

        );

        const result = await response.json();

        if (!response.ok) {

            throw new Error(

                result.message ||

                "Unable to create faculty."

            );

        }

        bootstrap.Modal.getInstance(

            document.getElementById("facultyModal")

        ).hide();

        showToast(

            "Faculty created successfully."

        );

        await loadFaculty();

    }

    catch (error) {

        console.error(error);

        showToast(

            error.message,

            "danger"

        );

    }

}

// =====================================================
// EDIT FACULTY
// =====================================================

async function editFaculty(id) {

    editFacultyId = id;

    try {

        const response = await fetch(

            facultyAPI + "/" + id,

            {

                headers: {

                    Authorization:

                        "Bearer " + facultyToken

                }

            }

        );

        const result = await response.json();

        if (!response.ok) {

            throw new Error(

                result.message ||

                "Unable to fetch faculty."

            );

        }

        const faculty = result.faculty;

        employeeId.value = faculty.employee_id || "";

        facultyName.value = faculty.faculty_name || "";

        facultyEmail.value = faculty.email || "";

        facultyMobile.value = faculty.mobile || "";

        facultySubject.value = faculty.subject || "";

        facultyRole.value = faculty.role || "FACULTY";

        facultyStatus.value =

            faculty.is_active

                ? "true"

                : "false";

        facultyPassword.value = "";

        facultyConfirmPassword.value = "";

        document.getElementById(

            "facultyModalTitle"

        ).innerHTML =

        '<i class="bi bi-pencil-square me-2"></i>Edit Faculty';

        saveFacultyBtn.classList.add(

            "d-none"

        );

        updateFacultyBtn.classList.remove(

            "d-none"

        );

        new bootstrap.Modal(

            document.getElementById(

                "facultyModal"

            )

        ).show();

    }

    catch (error) {

        console.error(error);

        showToast(

            error.message,

            "danger"

        );

    }

}

// =====================================================
// UPDATE FACULTY
// =====================================================

async function updateFaculty() {

    const data = {

        employee_id: employeeId.value.trim(),

        faculty_name: facultyName.value.trim(),

        email: facultyEmail.value.trim(),

        mobile: facultyMobile.value.trim(),

        subject: facultySubject.value.trim(),

        role: facultyRole.value,

        is_active:

            facultyStatus.value === "true"

    };

    try {

        const response = await fetch(

            facultyAPI + "/" + editFacultyId,

            {

                method: "PUT",

                headers: {

                    "Content-Type":

                        "application/json",

                    Authorization:

                        "Bearer " + facultyToken

                },

                body: JSON.stringify(data)

            }

        );

        const result = await response.json();

        if (!response.ok) {

            throw new Error(

                result.message ||

                "Unable to update faculty."

            );

        }

        bootstrap.Modal.getInstance(

            document.getElementById(

                "facultyModal"

            )

        ).hide();

        showToast(

            "Faculty updated successfully."

        );

        await loadFaculty();

    }

    catch (error) {

        console.error(error);

        showToast(

            error.message,

            "danger"

        );

    }

}
// =====================================================
// ENABLE / DISABLE FACULTY
// =====================================================

async function toggleFacultyStatus(id, currentStatus) {

    try {

        const faculty = facultyList.find(

            item => item.id === id

        );

        if (!faculty) {

            showToast(

                "Faculty not found.",

                "warning"

            );

            return;

        }

        const payload = {

            employee_id: faculty.employee_id,
            faculty_name: faculty.faculty_name,
            email: faculty.email,
            mobile: faculty.mobile,
            subject: faculty.subject,
            role: faculty.role,
            is_active: !currentStatus

        };

        const response = await fetch(

            facultyAPI + "/" + id,

            {

                method: "PUT",

                headers: {

                    "Content-Type": "application/json",

                    Authorization:
                        "Bearer " + facultyToken

                },

                body: JSON.stringify(payload)

            }

        );

        const result = await response.json();

        if (!response.ok) {

            throw new Error(result.message);

        }

        showToast(

            !currentStatus

                ? "Faculty Enabled"

                : "Faculty Disabled"

        );

        await loadFaculty();

    }

    catch (error) {

        console.error(error);

        showToast(error.message, "danger");

    }

}

// =====================================================
// DELETE FACULTY
// =====================================================

async function deleteFaculty(id) {

    if (

        !confirm(

            "Are you sure you want to delete this faculty?"

        )

    ) return;

    try {

        const response = await fetch(

            facultyAPI + "/" + id,

            {

                method: "DELETE",

                headers: {

                    Authorization:

                        "Bearer " + facultyToken

                }

            }

        );

        const result = await response.json();

        if (!response.ok) {

            throw new Error(result.message);

        }

        showToast(

            "Faculty deleted successfully."

        );

        await loadFaculty();

    }

    catch (error) {

        console.error(error);

        showToast(error.message, "danger");

    }

}

// =====================================================
// TOAST
// =====================================================

function showToast(message, type = "success") {

    const toastElement = document.getElementById(

        "facultyToast"

    );

    const toastMessage = document.getElementById(

        "facultyToastMessage"

    );

    if (!toastElement || !toastMessage) {

        alert(message);

        return;

    }

    toastMessage.innerText = message;

    toastElement.classList.remove(

        "text-bg-success",
        "text-bg-danger",
        "text-bg-warning"

    );

    if (type === "danger") {

        toastElement.classList.add(

            "text-bg-danger"

        );

    }

    else if (type === "warning") {

        toastElement.classList.add(

            "text-bg-warning"

        );

    }

    else {

        toastElement.classList.add(

            "text-bg-success"

        );

    }

    new bootstrap.Toast(

        toastElement

    ).show();

}

// =====================================================
// EXPORT FUNCTIONS
// =====================================================

window.openFacultyModal = openFacultyModal;
window.saveFaculty = saveFaculty;
window.editFaculty = editFaculty;
window.updateFaculty = updateFaculty;
window.deleteFaculty = deleteFaculty;
window.toggleFacultyStatus = toggleFacultyStatus;
window.searchFaculty = searchFaculty;
window.filterFaculty = filterFaculty;

// =====================================================
// INITIALIZE
// =====================================================

initializeFacultyModule();

// =====================================================
// CLOSE MODULE
// =====================================================

})();