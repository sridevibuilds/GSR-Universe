/* =====================================================
   GSR Universe ERP
   Students Module
===================================================== */

const STUDENT_TOKEN = localStorage.getItem("token");

let students = [];

/* =====================================================
   LOAD STUDENTS
===================================================== */

async function loadStudents() {

    try {

        const response = await fetch(

            API.students + "/all",

            {

                method: "GET",

                headers: {

                    Authorization: "Bearer " + STUDENT_TOKEN

                }

            }

        );

        const result = await response.json();

        if (result.success) {

            students = result.students;

            renderStudents(students);

        }

        else {

            document.getElementById("studentTableBody").innerHTML = `

                <tr>

                    <td colspan="7" class="text-center">

                        No Students Found

                    </td>

                </tr>

            `;

        }

    }

    catch (error) {

        console.log(error);

    }

}

/* =====================================================
   RENDER STUDENTS
===================================================== */

function renderStudents(studentList) {

    let html = "";

    studentList.forEach(student => {

        html += `

            <tr>

                <td>${student.admission_no}</td>

                <td>${student.student_name}</td>

                <td>${student.class_name}</td>

                <td>${student.section}</td>

                <td>${student.primary_parent_mobile}</td>

                <td>

                    <button
                        class="btn btn-primary btn-sm"
                        onclick="editStudent(${student.id})">

                        <i class="bi bi-pencil-fill"></i>

                    </button>

                    <button
                        class="btn btn-danger btn-sm"
                        onclick="deleteStudent(${student.id})">

                        <i class="bi bi-trash-fill"></i>

                    </button>

                </td>

            </tr>

        `;

    });

    if (studentList.length === 0) {

        html = `

            <tr>

                <td colspan="6" class="text-center">

                    No Students Available

                </td>

            </tr>

        `;

    }

    document.getElementById("studentTableBody").innerHTML = html;

}

/* =====================================================
   CLEAR FORM
===================================================== */

function clearForm() {

    document.getElementById("studentForm").reset();

    document.getElementById("studentId").value = "";

}

/* =====================================================
   NEW STUDENT
===================================================== */

document.addEventListener("click", function (e) {

    if (e.target.closest("[data-bs-target='#studentModal']")) {

        clearForm();

        document.getElementById("saveStudentBtn").classList.remove("d-none");

        document.getElementById("updateStudentBtn").classList.add("d-none");

    }

});

/* =====================================================
   INITIAL LOAD
===================================================== */

loadStudents();
/* =====================================================
   SAVE STUDENT
===================================================== */

async function saveStudent() {

    try {

        const body = {

            admission_no: document.getElementById("admissionNo").value,

            student_name: document.getElementById("studentName").value,

            class_name: document.getElementById("className").value,

            section: document.getElementById("section").value,

            primary_parent_name: document.getElementById("parentName").value,

            secondary_parent_name: document.getElementById("secondaryParentName").value,

            primary_parent_mobile: document.getElementById("parentMobile").value,

            secondary_parent_mobile: document.getElementById("secondaryParentMobile").value,

            parent_email: document.getElementById("parentEmail").value,

            date_of_birth: document.getElementById("dob").value

        };

        const response = await fetch(

            API.students + "/create",

            {

                method: "POST",

                headers: {

                    "Content-Type": "application/json",

                    Authorization: "Bearer " + STUDENT_TOKEN

                },

                body: JSON.stringify(body)

            }

        );

        const result = await response.json();

        if (result.success) {

            alert(result.message);

            bootstrap.Modal.getInstance(

                document.getElementById("studentModal")

            ).hide();

            clearForm();

            loadStudents();

        }

        else {

            alert(result.message);

        }

    }

    catch (error) {

        console.log(error);

        alert("Unable to save student.");

    }

}

/* =====================================================
   EDIT STUDENT
===================================================== */

async function editStudent(id) {

    try {

        const response = await fetch(

            API.students + "/" + id,

            {

                headers: {

                    Authorization: "Bearer " + STUDENT_TOKEN

                }

            }

        );

        const result = await response.json();

        if (result.success) {

            const s = result.student;

            document.getElementById("studentId").value = s.id;

            document.getElementById("admissionNo").value = s.admission_no;

            document.getElementById("studentName").value = s.student_name;

            document.getElementById("className").value = s.class_name;

            document.getElementById("section").value = s.section;

            document.getElementById("parentName").value = s.primary_parent_name;

            document.getElementById("secondaryParentName").value = s.secondary_parent_name;

            document.getElementById("parentMobile").value = s.primary_parent_mobile;

            document.getElementById("secondaryParentMobile").value = s.secondary_parent_mobile;

            document.getElementById("parentEmail").value = s.parent_email;

            document.getElementById("dob").value = s.date_of_birth;

            document.getElementById("saveStudentBtn").classList.add("d-none");

            document.getElementById("updateStudentBtn").classList.remove("d-none");

            new bootstrap.Modal(

                document.getElementById("studentModal")

            ).show();

        }

    }

    catch (error) {

        console.log(error);

    }

}

/* =====================================================
   UPDATE STUDENT
===================================================== */

async function updateStudent() {

    try {

        const id = document.getElementById("studentId").value;

        const body = {

            student_name: document.getElementById("studentName").value,

            class_name: document.getElementById("className").value,

            section: document.getElementById("section").value,

            primary_parent_name: document.getElementById("parentName").value,

            secondary_parent_name: document.getElementById("secondaryParentName").value,

            primary_parent_mobile: document.getElementById("parentMobile").value,

            secondary_parent_mobile: document.getElementById("secondaryParentMobile").value,

            parent_email: document.getElementById("parentEmail").value,

            date_of_birth: document.getElementById("dob").value

        };

        const response = await fetch(

            API.students + "/update/" + id,

            {

                method: "PUT",

                headers: {

                    "Content-Type": "application/json",

                    Authorization: "Bearer " + STUDENT_TOKEN

                },

                body: JSON.stringify(body)

            }

        );

        const result = await response.json();

        if (result.success) {

            alert(result.message);

            bootstrap.Modal.getInstance(

                document.getElementById("studentModal")

            ).hide();

            clearForm();

            loadStudents();

        }

        else {

            alert(result.message);

        }

    }

    catch (error) {

        console.log(error);

    }

}
/* =====================================================
   DELETE STUDENT
===================================================== */

async function deleteStudent(id) {

    if (!confirm("Are you sure you want to delete this student?")) {

        return;

    }

    try {

        const response = await fetch(

            API.students + "/delete/" + id,

            {

                method: "DELETE",

                headers: {

                    Authorization: "Bearer " + STUDENT_TOKEN

                }

            }

        );

        const result = await response.json();

        if (result.success) {

            alert(result.message);

            loadStudents();

        } else {

            alert(result.message);

        }

    } catch (error) {

        console.log(error);

        alert("Unable to delete student.");

    }

}


/* =====================================================
   SEARCH STUDENTS
===================================================== */

document.getElementById("studentSearch").addEventListener("keyup", function () {

    const keyword = this.value.toLowerCase();

    const filteredStudents = students.filter(student =>

        student.student_name.toLowerCase().includes(keyword) ||

        student.admission_no.toLowerCase().includes(keyword)

    );

    renderStudents(filteredStudents);

});


/* =====================================================
   FILTER BY CLASS
===================================================== */

document.getElementById("classFilter").addEventListener("change", function () {

    const selectedClass = this.value;

    if (selectedClass === "") {

        renderStudents(students);

        return;

    }

    const filteredStudents = students.filter(student =>

        student.class_name === selectedClass

    );

    renderStudents(filteredStudents);

});


/* =====================================================
   REFRESH STUDENTS
===================================================== */

function refreshStudents() {

    loadStudents();

}


/* =====================================================
   MODULE INITIALIZATION
===================================================== */

document.addEventListener("DOMContentLoaded", () => {

    loadStudents();

});


/* =====================================================
   MODULE READY
===================================================== */

console.log("Students Module Loaded Successfully");