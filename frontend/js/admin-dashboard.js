/* =====================================================
   GSR Universe ERP
   Admin Dashboard
===================================================== */

// =====================================================
// GLOBAL VARIABLES
// =====================================================

const TOKEN = localStorage.getItem("token");

const ADMIN = JSON.parse(

    localStorage.getItem("admin")

);

if (!TOKEN) {

    window.location.href = "index.html";

}

// =====================================================
// INITIALIZE DASHBOARD
// =====================================================

document.addEventListener(

    "DOMContentLoaded",

    initializeDashboard

);

function initializeDashboard() {

    loadAdmin();

    loadDashboard();

    updateSidebar("dashboard");

}

// =====================================================
// LOAD ADMIN DETAILS
// =====================================================

function loadAdmin() {

    const adminName =

        document.getElementById(

            "adminName"

        );

    if (!adminName) return;

    adminName.textContent =

        ADMIN?.admin_name ||

        "Administrator";

}

// =====================================================
// LOAD DASHBOARD
// =====================================================

async function loadDashboard() {

    await loadFacultyCount();

    await loadOverviewMetrics();

}

async function loadOverviewMetrics() {
    try {
        const response = await fetch(
            API.adminOverview,
            {
                headers: {
                    Authorization: "Bearer " + TOKEN
                }
            }
        );
        const result = await response.json();
        if (response.ok && result.success && result.overview) {
            const totalStudentsEl = document.getElementById("totalStudents");
            if (totalStudentsEl) {
                totalStudentsEl.textContent = result.overview.total_students || 0;
            }
            const outstandingFeeEl = document.getElementById("outstandingFees");
            if (outstandingFeeEl) {
                outstandingFeeEl.textContent = "₹" + (result.overview.outstanding_fee_amount || 0).toLocaleString();
            }
        }
    } catch (error) {
        console.error("Overview Metrics Error:", error);
    }
}

// =====================================================
// LOAD FACULTY COUNT
// =====================================================

async function loadFacultyCount() {

    try {

        const response = await fetch(

            API.faculty,

            {

                headers: {

                    Authorization:

                        "Bearer " + TOKEN

                }

            }

        );

        const result = await response.json();

        if (!response.ok) {

            throw new Error(

                result.message

            );

        }

        const faculty =

            result.faculty || [];

        const total = faculty.length;

        const active = faculty.filter(

            item => item.is_active

        ).length;

        const disabled =

            total - active;

        document.getElementById(

            "totalFaculty"

        ).textContent = total;

        document.getElementById(

            "activeFaculty"

        ).textContent = active;

        document.getElementById(

            "disabledFaculty"

        ).textContent = disabled;

    }

    catch (error) {

        console.error(

            "Dashboard Error:",

            error

        );

    }

}

// =====================================================
// LOAD MODULE
// =====================================================
// =====================================================
// LOAD MODULE
// =====================================================

async function loadModule(moduleName) {

    try {

        const container = document.getElementById(

            "moduleContainer"

        );

        container.innerHTML = `

<div class="text-center py-5">

    <div class="spinner-border text-primary"></div>

    <p class="mt-3">

        Loading ${moduleName}...

    </p>

</div>

`;

        const response = await fetch(

            `modules/${moduleName}.html`

        );

        if (!response.ok) {

            throw new Error(

                "Unable to load module HTML."

            );

        }

        container.innerHTML =

            await response.text();

        await loadModuleScript(

            moduleName

        );

        updateSidebar(moduleName);

    }

    catch (error) {

        console.error(error);

        document.getElementById(

            "moduleContainer"

        ).innerHTML = `

<div class="alert alert-danger">

    <h5>

        Failed to load module

    </h5>

    <p>

        ${error.message}

    </p>

</div>

`;

    }

}

// =====================================================
// LOAD MODULE SCRIPT
// =====================================================

function loadModuleScript(moduleName) {

    return new Promise((resolve, reject) => {

        const oldScript = document.getElementById(

            "dynamicModuleScript"

        );

        if (oldScript) {

            oldScript.remove();

        }

        const script = document.createElement(

            "script"

        );

        script.id =

            "dynamicModuleScript";

        script.src =

            `js/${moduleName}.js?v=${Date.now()}`;

        script.onload = () => {

            console.log(

                moduleName +

                " loaded successfully."

            );

            resolve();

        };

        script.onerror = () => {

            reject(

                new Error(

                    "Unable to load JavaScript."

                )

            );

        };

        document.body.appendChild(

            script

        );

    });

}

// =====================================================
// SHOW DASHBOARD
// =====================================================

function showDashboard() {

    const container = document.getElementById(

        "moduleContainer"

    );

    if (container) {

        container.innerHTML = "";

    }

    loadDashboard();

    updateSidebar(

        "dashboard"

    );

}

// =====================================================
// UPDATE SIDEBAR
// =====================================================

function updateSidebar(activeModule) {

    document

        .querySelectorAll(

            ".sidebar-menu li"

        )

        .forEach(item =>

            item.classList.remove(

                "active"

            )

        );

    const target = document.querySelector(

        `.sidebar-menu li[data-module="${activeModule}"]`

    );

    if (target) {

        target.classList.add(

            "active"

        );

    }

}
// =====================================================
// LOGOUT
// =====================================================

function logout() {

    if (

        !confirm(

            "Are you sure you want to logout?"

        )

    ) {

        return;

    }

    localStorage.clear();

    window.location.href = "index.html";

}

// =====================================================
// REFRESH DASHBOARD
// =====================================================

async function refreshDashboard() {

    try {

        await loadFacultyCount();

    }

    catch (error) {

        console.error(

            "Refresh failed:",

            error

        );

    }

}

// =====================================================
// DASHBOARD AUTO REFRESH
// =====================================================

let refreshTimer = null;

function startAutoRefresh() {

    stopAutoRefresh();

    refreshTimer = setInterval(

        refreshDashboard,

        60000

    );

}

function stopAutoRefresh() {

    if (refreshTimer) {

        clearInterval(

            refreshTimer

        );

        refreshTimer = null;

    }

}

// =====================================================
// WINDOW EVENTS
// =====================================================

window.addEventListener(

    "focus",

    refreshDashboard

);

document.addEventListener(

    "visibilitychange",

    () => {

        if (

            document.visibilityState ===

            "visible"

        ) {

            refreshDashboard();

        }

    }

);

// =====================================================
// START AUTO REFRESH
// =====================================================

startAutoRefresh();
// =====================================================
// FACULTY MODULE CALLBACKS
// =====================================================

function onFacultyCreated() {

    refreshDashboard();

}

function onFacultyUpdated() {

    refreshDashboard();

}

function onFacultyDeleted() {

    refreshDashboard();

}

function onFacultyStatusChanged() {

    refreshDashboard();

}

// =====================================================
// LOADING OVERLAY
// =====================================================

function showLoading() {

    const loading = document.getElementById(

        "loadingModal"

    );

    if (!loading) return;

    const modal = new bootstrap.Modal(

        loading,

        {

            backdrop: "static",

            keyboard: false

        }

    );

    modal.show();

}

function hideLoading() {

    const loading = document.getElementById(

        "loadingModal"

    );

    if (!loading) return;

    const modal = bootstrap.Modal.getInstance(

        loading

    );

    if (modal) {

        modal.hide();

    }

}

// =====================================================
// DASHBOARD ERROR
// =====================================================

function showDashboardError(message) {

    const container = document.getElementById(

        "moduleContainer"

    );

    if (!container) return;

    container.innerHTML = `

<div class="alert alert-danger mt-4">

    <h5>

        <i class="bi bi-exclamation-triangle-fill me-2"></i>

        Error

    </h5>

    <p class="mb-0">

        ${message}

    </p>

</div>

`;

}

// =====================================================
// GLOBAL FUNCTIONS
// =====================================================

window.loadModule = loadModule;

window.showDashboard = showDashboard;

window.refreshDashboard = refreshDashboard;

window.logout = logout;

window.showLoading = showLoading;

window.hideLoading = hideLoading;

window.showDashboardError = showDashboardError;

window.onFacultyCreated = onFacultyCreated;

window.onFacultyUpdated = onFacultyUpdated;

window.onFacultyDeleted = onFacultyDeleted;

window.onFacultyStatusChanged = onFacultyStatusChanged;
// =====================================================
// CLEANUP EVENTS
// =====================================================

window.addEventListener(

    "beforeunload",

    () => {

        stopAutoRefresh();

    }

);

// =====================================================
// MODULE NAVIGATION
// =====================================================

function openFacultyManagement() {

    loadModule("faculty");

}

window.openFacultyManagement =

    openFacultyManagement;

// =====================================================
// SIDEBAR NAVIGATION
// =====================================================

document.addEventListener(

    "click",

    function (event) {

        const item = event.target.closest(

            ".sidebar-menu li"

        );

        if (!item) return;

        document

            .querySelectorAll(

                ".sidebar-menu li"

            )

            .forEach(menu =>

                menu.classList.remove(

                    "active"

                )

            );

        item.classList.add(

            "active"

        );

    }

);

// =====================================================
// PAGE READY
// =====================================================

initializeDashboard();

// =====================================================
// DEBUG
// =====================================================

console.group(

    "🚀 GSR Universe ERP"

);

console.log(

    "Admin Dashboard Ready"

);

console.log(

    "Admin :",

    ADMIN

);

console.log(

    "API :",

    API.faculty

);

console.groupEnd();

// =====================================================
// END
// =====================================================