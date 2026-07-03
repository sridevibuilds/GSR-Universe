// ======================================================
// GSR Universe ERP
// Faculty Dashboard JS
// Part 3A - Block 1
// ======================================================

// ==========================================
// API BASE URL
// ==========================================

const API_BASE_URL = "http://localhost:5000/api";

// ==========================================
// TOKEN
// ==========================================

const token = localStorage.getItem("token");

if (!token) {

    window.location.href = "index.html";

}

// ==========================================
// FACULTY DATA
// ==========================================

let facultyData = JSON.parse(

    localStorage.getItem("faculty")

) || {};

// ==========================================
// COMMON FETCH HEADERS
// ==========================================

const authHeaders = {

    "Content-Type": "application/json",

    "Authorization": `Bearer ${token}`

};

// ==========================================
// PAGE LOAD
// ==========================================

window.addEventListener(

    "DOMContentLoaded",

    () => {

        loadFacultyProfile();

        initializeSidebar();

        initializeQuickActions();

    }

);

// ==========================================
// LOAD FACULTY PROFILE
// ==========================================

async function loadFacultyProfile() {

    try {

        const response = await fetch(

            API_BASE_URL + "/faculty/profile",

            {

                method: "GET",

                headers: authHeaders

            }

        );

        const result = await response.json();

        if (!response.ok) {

            logout();

            return;

        }

        facultyData = result.faculty;

        localStorage.setItem(

            "faculty",

            JSON.stringify(facultyData)

        );

        document.getElementById(

            "facultyName"

        ).innerText =

            facultyData.faculty_name;

        document.getElementById(

            "facultySubject"

        ).innerText =

            facultyData.subject || "Faculty";

    }

    catch (error) {

        console.error(

            "Faculty Profile Error",

            error

        );

    }

}

// ==========================================
// SIDEBAR
// ==========================================

function initializeSidebar() {

    const menuItems =

        document.querySelectorAll(

            ".menu li[data-module]"

        );

    menuItems.forEach(item => {

        item.addEventListener(

            "click",

            function () {

                menuItems.forEach(

                    m => m.classList.remove(

                        "active"

                    )

                );

                this.classList.add(

                    "active"

                );

                const module =

                    this.dataset.module;

                loadModule(module);

            }

        );

    });

}

// ==========================================
// QUICK ACTIONS
// ==========================================

function initializeQuickActions() {

    document

        .querySelectorAll(

            ".quick-action"

        )

        .forEach(button => {

            button.addEventListener(

                "click",

                function () {

                    const module =

                        this.dataset.module;

                    loadModule(module);

                }

            );

        });

}
// ======================================================
// Part 3A - Block 2
// ======================================================

// ==========================================
// MODULE LOADER (Placeholder)
// ==========================================

// ======================================================
// GSR Universe ERP
// Part 3B
// Dynamic Module Loader
// ======================================================

// ==========================================
// MODULE PATHS
// ==========================================

const moduleFiles = {

    dashboard: null,

    student: "modules/student.html",

    attendance: "modules/attendance.html",

    assessment: "modules/assessment.html",

    "assessment-result": "modules/assessment-result.html",

    homework: "modules/homework.html",

    assignment: "modules/assignment.html",

    "progress-card": "modules/progress-card.html",

    fees: "modules/fees.html",

    timetable: "modules/timetable.html",

    announcement: "modules/announcement.html",

    events: "modules/events.html",

    holidays: "modules/holidays.html",

    noticeboard: "modules/noticeboard.html",

    transport: "modules/transport.html"

};

// ==========================================
// LOAD MODULE
// ==========================================

async function loadModule(module) {

    if (module === "dashboard") {

        showDashboard();

        return;

    }

    const content = document.getElementById("module-content");

    document.getElementById("dashboard-home").style.display = "none";

    content.innerHTML = `

        <div class="text-center py-5">

            <div class="spinner-border text-primary"></div>

            <h5 class="mt-3">

                Loading ${module}...

            </h5>

        </div>

    `;

    try {

        const response = await fetch(

            moduleFiles[module]

        );

        if (!response.ok) {

            throw new Error(

                "Module Not Found"

            );

        }

        const html = await response.text();

        content.innerHTML = html;

        initializeModule(module);

    }

    catch(error){

        console.error(error);

        content.innerHTML = `

            <div class="alert alert-danger">

                <h4>

                    Module Failed To Load

                </h4>

                <hr>

                <p>

                    ${module} module could not be loaded.

                </p>

            </div>

        `;

    }

}

// ==========================================
// INITIALIZE MODULES
// ==========================================

function initializeModule(module){

    switch(module){

        case "student":

            if(typeof loadStudents==="function"){

                loadStudents();

            }

            break;

        case "attendance":

            if(typeof loadAttendance==="function"){

                loadAttendance();

            }

            break;

        case "assessment":

            if(typeof loadAssessments==="function"){

                loadAssessments();

            }

            break;

        case "assessment-result":

            if(typeof loadAssessmentResults==="function"){

                loadAssessmentResults();

            }

            break;

        case "homework":

            if(typeof loadHomework==="function"){

                loadHomework();

            }

            break;

        case "assignment":

            if(typeof loadAssignments==="function"){

                loadAssignments();

            }

            break;

        case "progress-card":

            if(typeof loadProgressCards==="function"){

                loadProgressCards();

            }

            break;

        case "fees":

            if(typeof loadFees==="function"){

                loadFees();

            }

            break;

        case "timetable":

            if(typeof loadTimetable==="function"){

                loadTimetable();

            }

            break;

        case "announcement":

            if(typeof loadAnnouncements==="function"){

                loadAnnouncements();

            }

            break;

        case "events":

            if(typeof loadEvents==="function"){

                loadEvents();

            }

            break;

        case "holidays":

            if(typeof loadHolidays==="function"){

                loadHolidays();

            }

            break;

        case "noticeboard":

            if(typeof loadNoticeBoard==="function"){

                loadNoticeBoard();

            }

            break;

        case "transport":

            if(typeof loadTransport==="function"){

                loadTransport();

            }

            break;

    }

}

// ==========================================
// DASHBOARD BUTTON
// ==========================================

document

.querySelector(

'.menu li[data-module="dashboard"]'

)

.addEventListener(

"click",

showDashboard

);

// ==========================================
// DEFAULT PAGE
// ==========================================

showDashboard();

console.log(

"✅ Dynamic Module Loader Ready"

);

// ==========================================
// LOGOUT
// ==========================================

function logout() {

    localStorage.removeItem("token");

    localStorage.removeItem("faculty");

    window.location.href = "index.html";

}

document

    .getElementById("logoutBtn")

    .addEventListener(

        "click",

        function () {

            if (

                confirm(

                    "Are you sure you want to logout?"

                )

            ) {

                logout();

            }

        }

    );

// ==========================================
// DASHBOARD HOME
// ==========================================

function showDashboard() {

    document.getElementById(

        "dashboard-home"

    ).style.display = "block";

    document.getElementById(

        "module-content"

    ).innerHTML = "";

}

// ==========================================
// ESC KEY SUPPORT
// ==========================================

document.addEventListener(

    "keydown",

    function (event) {

        if (

            event.key === "Escape"

        ) {

            showDashboard();

        }

    }

);

// ==========================================
// READY
// ==========================================

console.log(

    "✅ Faculty Dashboard Loaded Successfully"

);