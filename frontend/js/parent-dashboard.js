// ======================================================
// GSR Universe ERP
// Parent Dashboard JS
// Part 3A
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
// PARENT DATA
// ==========================================

let parentData = JSON.parse(

    localStorage.getItem("user")

) || {};

// ==========================================
// HEADERS
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

        loadParentProfile();

        initializeSidebar();

        initializeQuickActions();

    }

);

// ==========================================
// LOAD PARENT PROFILE
// ==========================================

function loadParentProfile() {

    document.getElementById(

        "parentName"

    ).innerText =

        parentData.primary_parent_name ||

        "Parent";

    document.getElementById(

        "studentName"

    ).innerText =

        parentData.student_name ||

        "Student";

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

                    loadModule(

                        this.dataset.module

                    );

                }

            );

        });

}

// ==========================================
// SHOW DASHBOARD
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
// LOGOUT
// ==========================================

function logout() {

    localStorage.removeItem("token");

    localStorage.removeItem("user");

    window.location.href = "index.html";

}

document

.getElementById(

"logoutBtn"

)

.addEventListener(

"click",

function(){

    if(

        confirm(

            "Logout?"

        )

    ){

        logout();

    }

}

);

console.log(

"✅ Parent Dashboard Loaded"

);
// ======================================================
// GSR Universe ERP
// Parent Dashboard JS
// Part 3B
// ======================================================

// ==========================================
// MODULE FILES
// ==========================================

const moduleFiles = {

    dashboard: null,

    attendance: "modules/attendance.html",

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

    const moduleContent = document.getElementById("module-content");

    document.getElementById("dashboard-home").style.display = "none";

    moduleContent.innerHTML = `

        <div class="text-center py-5">

            <div class="spinner-border text-primary"></div>

            <h5 class="mt-3">

                Loading ${module}...

            </h5>

        </div>

    `;

    try {

        const response = await fetch(moduleFiles[module]);

        if (!response.ok) {

            throw new Error("Module Not Found");

        }

        const html = await response.text();

        moduleContent.innerHTML = html;

        initializeModule(module);

    }

    catch (error) {

        console.error(error);

        moduleContent.innerHTML = `

            <div class="alert alert-danger">

                <h4>

                    Module Failed To Load

                </h4>

                <hr>

                <p>

                    ${module} module not found.

                </p>

            </div>

        `;

    }

}

// ==========================================
// INITIALIZE MODULE
// ==========================================

function initializeModule(module){

    switch(module){

        case "attendance":

            if(typeof loadAttendance==="function"){

                loadAttendance();

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
// DASHBOARD MENU
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
// DEFAULT HOME
// ==========================================

showDashboard();

console.log(

"✅ Parent Dashboard Ready"

);