/* =====================================================
   GSR Universe ERP
   Admin Dashboard
   Part 1
===================================================== */

// ==========================================
// TOKEN
// ==========================================

const TOKEN = localStorage.getItem("token");

if (!TOKEN) {

    window.location.href = "index.html";

}

// ==========================================
// USER
// ==========================================

const USER = JSON.parse(

    localStorage.getItem("user")

);

// ==========================================
// API
// ==========================================

const API_BASE = "http://localhost:5000/api";

// ==========================================
// INITIALIZATION
// ==========================================

document.addEventListener(

    "DOMContentLoaded",

    () => {

        loadAdmin();

        loadDashboard();

    }

);

// ==========================================
// LOAD ADMIN DETAILS
// ==========================================

function loadAdmin() {

    if (!USER) return;

    const adminName = document.getElementById(

        "adminName"

    );

    if (adminName) {

        adminName.innerHTML =

            USER.admin_name ||

            USER.name ||

            "Administrator";

    }

}

// ==========================================
// LOAD DASHBOARD
// ==========================================

async function loadDashboard() {

    await loadFacultyCount();

}

// ==========================================
// LOAD FACULTY COUNT
// ==========================================

async function loadFacultyCount() {

    try {

        const response = await fetch(

            API_BASE + "/faculty",

            {

                method: "GET",

                headers: {

                    Authorization:

                        "Bearer " + TOKEN

                }

            }

        );

        const result = await response.json();

        const faculty =

            result.faculty || [];

        const totalFaculty =

            document.getElementById(

                "totalFaculty"

            );

        const activeFaculty =

            document.getElementById(

                "activeFaculty"

            );

        const disabledFaculty =

            document.getElementById(

                "disabledFaculty"

            );

        if (totalFaculty)

            totalFaculty.innerHTML =

                faculty.length;

        let active = 0;

        let inactive = 0;

        faculty.forEach(f => {

            if (f.is_active)

                active++;

            else

                inactive++;

        });

        if (activeFaculty)

            activeFaculty.innerHTML = active;

        if (disabledFaculty)

            disabledFaculty.innerHTML = inactive;

    }

    catch (error) {

        console.error(error);

    }

}

// ==========================================
// LOAD MODULE
// ==========================================

async function loadModule(moduleName) {

    try {

        const response = await fetch(

            "modules/" +

            moduleName +

            ".html"

        );

        if (!response.ok) {

            throw new Error(

                "Module not found"

            );

        }

        const html =

            await response.text();

        document.getElementById(

            "moduleContainer"

        ).innerHTML = html;

        loadModuleScript(moduleName);

    }

    catch (error) {

        console.error(error);

        document.getElementById(

            "moduleContainer"

        ).innerHTML = `

<div class="alert alert-danger mt-4">

<h5>Unable to Load Module</h5>

<p>${moduleName}</p>

</div>

`;

    }

}

// ==========================================
// LOAD MODULE JS
// ==========================================

function loadModuleScript(moduleName) {

    const oldScript = document.getElementById(

        "dynamicModuleScript"

    );

    if (oldScript) {

        oldScript.remove();

    }

    const script =

        document.createElement("script");

    script.id =

        "dynamicModuleScript";

    script.src =

        "js/" +

        moduleName +

        ".js?v=" +

        new Date().getTime();

    document.body.appendChild(script);

}

console.log("✅ Admin Dashboard Part 1 Loaded");
/* =====================================================
   Admin Dashboard
   Part 2
===================================================== */

// ==========================================
// SHOW DASHBOARD
// ==========================================

function showDashboard() {

    const moduleContainer = document.getElementById("moduleContainer");

    if (moduleContainer) {

        moduleContainer.innerHTML = "";

    }

    loadDashboard();

}

// ==========================================
// SIDEBAR ACTIVE MENU
// ==========================================

document.addEventListener("click", function (e) {

    const item = e.target.closest(".sidebar-menu li");

    if (!item) return;

    document.querySelectorAll(".sidebar-menu li").forEach(menu => {

        menu.classList.remove("active");

    });

    item.classList.add("active");

});

// ==========================================
// QUICK ACTIONS
// ==========================================

function openFacultyManagement() {

    loadModule("faculty");

}

window.openFacultyManagement = openFacultyManagement;

// ==========================================
// LOGOUT
// ==========================================

function logout() {

    if (!confirm("Are you sure you want to logout?")) {

        return;

    }

    localStorage.removeItem("token");
    localStorage.removeItem("user");
    localStorage.removeItem("admin");
    localStorage.removeItem("faculty");
    localStorage.removeItem("parent");
    localStorage.removeItem("user_id");
    localStorage.removeItem("faculty_id");

    window.location.href = "index.html";

}

window.logout = logout;

// ==========================================
// REFRESH DASHBOARD
// ==========================================

async function refreshDashboard() {

    await loadDashboard();

}

window.refreshDashboard = refreshDashboard;

// ==========================================
// AUTO REFRESH
// ==========================================

setInterval(() => {

    refreshDashboard();

}, 60000);

console.log("✅ Admin Dashboard Part 2 Loaded");
/* =====================================================
   Admin Dashboard
   Part 3
===================================================== */

// ==========================================
// QUICK ACTION BUTTONS
// ==========================================

document.addEventListener("DOMContentLoaded", () => {

    const addBtn = document.getElementById("addFacultyBtn");
    const editBtn = document.getElementById("editFacultyBtn");
    const deleteBtn = document.getElementById("deleteFacultyBtn");

    if (addBtn) {

        addBtn.onclick = () => {

            loadModule("faculty");

        };

    }

    if (editBtn) {

        editBtn.onclick = () => {

            loadModule("faculty");

        };

    }

    if (deleteBtn) {

        deleteBtn.onclick = () => {

            loadModule("faculty");

        };

    }

});

// ==========================================
// GLOBAL FUNCTIONS
// ==========================================

window.loadModule = loadModule;
window.showDashboard = showDashboard;
window.logout = logout;
window.refreshDashboard = refreshDashboard;
window.openFacultyManagement = openFacultyManagement;

// ==========================================
// READY
// ==========================================

console.log("✅ GSR Universe Admin Dashboard Ready");