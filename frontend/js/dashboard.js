// =======================================
// Dashboard Initialization
// =======================================

document.addEventListener("DOMContentLoaded", () => {

    loadDashboard();

    setupSidebar();

});

// =======================================
// Sidebar Active Menu
// =======================================

function setupSidebar() {

    document.querySelectorAll(".sidebar li").forEach(item => {

        item.addEventListener("click", () => {

            document.querySelectorAll(".sidebar li").forEach(li => {

                li.classList.remove("active");

            });

            item.classList.add("active");

        });

    });

}

// =======================================
// Dashboard Data
// =======================================

async function loadDashboard() {

    loadStudentCount();

    loadFacultyCount();

}

// =======================================
// Student Count
// =======================================

async function loadStudentCount() {

    try {

        const response = await fetch(API.students);

        const result = await response.json();

        document.getElementById("studentCount").innerHTML = result.count || 0;

    } catch (error) {

        console.log(error);

    }

}

// =======================================
// Faculty Count
// =======================================

async function loadFacultyCount() {

    try {

        const response = await fetch(API.faculty);

        const result = await response.json();

        document.getElementById("facultyCount").innerHTML = result.count || 0;

    } catch (error) {

        console.log(error);

    }

}