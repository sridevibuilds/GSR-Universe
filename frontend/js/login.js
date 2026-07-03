// ======================================================
// GSR Universe ERP
// Login System
// Part 1
// ======================================================

// ==========================================
// CURRENT ROLE
// ==========================================

let currentRole = "ADMIN";

// ==========================================
// MESSAGE
// ==========================================

function showMessage(message, success = false) {

    const msg = document.getElementById("message");

    msg.innerHTML = message;

    msg.className = success

        ? "text-success mt-3 text-center"

        : "text-danger mt-3 text-center";

}

// ==========================================
// ROLE SELECTION
// ==========================================

function selectRole(role) {

    currentRole = role;

    document
        .querySelectorAll(".role-card")
        .forEach(card => card.classList.remove("active"));

    if (role === "ADMIN") {

        document
            .getElementById("adminCard")
            .classList.add("active");

        document
            .getElementById("usernameLabel")
            .innerText = "Email";

        document
            .getElementById("username")
            .placeholder = "Enter Admin Email";

        document
            .getElementById("passwordSection")
            .classList.remove("d-none");

        document
            .getElementById("otpSection")
            .classList.add("d-none");

        document
            .getElementById("loginBtn")
            .classList.remove("d-none");

        document
            .getElementById("sendOtpBtn")
            .classList.add("d-none");

        document
            .getElementById("verifyOtpBtn")
            .classList.add("d-none");

    }

    else if (role === "FACULTY") {

        document
            .getElementById("facultyCard")
            .classList.add("active");

        document
            .getElementById("usernameLabel")
            .innerText = "Email";

        document
            .getElementById("username")
            .placeholder = "Enter Faculty Email";

        document
            .getElementById("passwordSection")
            .classList.remove("d-none");

        document
            .getElementById("otpSection")
            .classList.add("d-none");

        document
            .getElementById("loginBtn")
            .classList.remove("d-none");

        document
            .getElementById("sendOtpBtn")
            .classList.add("d-none");

        document
            .getElementById("verifyOtpBtn")
            .classList.add("d-none");

    }

    else {

        document
            .getElementById("parentCard")
            .classList.add("active");

        document
            .getElementById("usernameLabel")
            .innerText = "Mobile Number";

        document
            .getElementById("username")
            .placeholder = "Enter Mobile Number";

        document
            .getElementById("passwordSection")
            .classList.add("d-none");

        document
            .getElementById("otpSection")
            .classList.add("d-none");

        document
            .getElementById("loginBtn")
            .classList.add("d-none");

        document
            .getElementById("sendOtpBtn")
            .classList.remove("d-none");

        document
            .getElementById("verifyOtpBtn")
            .classList.add("d-none");

    }

    showMessage("");

}

// ==========================================
// DEFAULT ROLE
// ==========================================

window.onload = () => {

    selectRole("ADMIN");

};
// ======================================================
// LOGIN
// ======================================================

async function login() {

    const username = document
        .getElementById("username")
        .value
        .trim();

    const password = document
        .getElementById("password")
        .value
        .trim();

    if (!username || !password) {

        showMessage("Please enter all fields.");

        return;

    }

    try {

        let endpoint = "";

        if (currentRole === "ADMIN") {

            endpoint = "/auth/admin/login";

        }

        else if (currentRole === "FACULTY") {

            endpoint = "/auth/faculty/login";

        }

        const response = await fetch(

            API_BASE_URL + endpoint,

            {

                method: "POST",

                headers: {

                    "Content-Type": "application/json"

                },

                body: JSON.stringify({

                    email: username,

                    password: password

                })

            }

        );

        const result = await response.json();

        if (!response.ok) {

            showMessage(

                result.message ||

                "Login Failed"

            );

            return;

        }

        localStorage.setItem(

            "token",

            result.token

        );

        if (currentRole === "ADMIN") {

            localStorage.setItem(

                "admin",

                JSON.stringify(result.admin)

            );

            showMessage(

                "Admin Login Successful",

                true

            );

            setTimeout(() => {

                window.location.href =

                    "admin-dashboard.html";

            }, 700);

        }

        else if (currentRole === "FACULTY") {

            localStorage.setItem(

                "faculty",

                JSON.stringify(result.faculty)

            );

            showMessage(

                "Faculty Login Successful",

                true

            );

            setTimeout(() => {

                window.location.href =

                    "faculty-dashboard.html";

            }, 700);

        }

    }

    catch (error) {

        console.error(error);

        showMessage(

            "Unable to connect to server."

        );

    }

}
// ======================================================
// SEND OTP
// ======================================================

async function sendOTP() {

    const mobile = document
        .getElementById("username")
        .value
        .trim();

    if (!mobile) {

        showMessage("Please enter your mobile number.");

        return;

    }

    try {

        const response = await fetch(

            API_BASE_URL + "/auth/parent/send-otp",

            {

                method: "POST",

                headers: {

                    "Content-Type": "application/json"

                },

                body: JSON.stringify({

                    mobile: mobile

                })

            }

        );

        const result = await response.json();

        if (!response.ok) {

            showMessage(

                result.message ||

                "Failed to send OTP."

            );

            return;

        }

        showMessage(

            "OTP Sent Successfully. Use 123456",

            true

        );

        document
            .getElementById("otpSection")
            .classList.remove("d-none");

        document
            .getElementById("sendOtpBtn")
            .classList.add("d-none");

        document
            .getElementById("verifyOtpBtn")
            .classList.remove("d-none");

    }

    catch (error) {

        console.error(error);

        showMessage(

            "Unable to connect to server."

        );

    }

}

// ======================================================
// VERIFY OTP
// ======================================================

async function verifyOTP() {

    const mobile = document
        .getElementById("username")
        .value
        .trim();

    const otp = document
        .getElementById("otp")
        .value
        .trim();

    if (!mobile || !otp) {

        showMessage(

            "Please enter OTP."

        );

        return;

    }

    try {

        const response = await fetch(

            API_BASE_URL + "/auth/parent/verify-otp",

            {

                method: "POST",

                headers: {

                    "Content-Type": "application/json"

                },

                body: JSON.stringify({

                    mobile: mobile,

                    otp: otp

                })

            }

        );

        const result = await response.json();

        if (!response.ok) {

            showMessage(

                result.message ||

                "OTP Verification Failed."

            );

            return;

        }

        localStorage.setItem(

            "token",

            result.token

        );

        localStorage.setItem(

            "user",

            JSON.stringify(result.student)

        );

        showMessage(

            "Parent Login Successful",

            true

        );

        setTimeout(() => {

            window.location.href =

                "parent-dashboard.html";

        }, 700);

    }

    catch (error) {

        console.error(error);

        showMessage(

            "Unable to connect to server."

        );

    }

}

// ======================================================
// ENTER KEY SUPPORT
// ======================================================

document.addEventListener(

    "keypress",

    function (event) {

        if (event.key === "Enter") {

            if (currentRole === "PARENT") {

                const otpVisible =

                    !document
                        .getElementById("otpSection")
                        .classList.contains("d-none");

                if (otpVisible) {

                    verifyOTP();

                } else {

                    sendOTP();

                }

            }

            else {

                login();

            }

        }

    }

);

// ======================================================
// READY
// ======================================================

console.log(

    "✅ Login System Loaded Successfully"

);