async function testLiveParentLogin() {
    console.log("Testing live Parent Send OTP & Verify OTP with registered mobile 9014561612...");

    const sendRes = await fetch("http://localhost:5000/api/auth/parent/send-otp", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ mobile: "9014561612" })
    });
    const sendData = await sendRes.json();
    console.log("Send OTP Response:", sendRes.status, sendData);

    const verifyRes = await fetch("http://localhost:5000/api/auth/parent/verify-otp", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ mobile: "9014561612", otp: sendData.otp || "123456" })
    });
    const verifyData = await verifyRes.json();
    console.log("Verify OTP Response:", verifyRes.status, verifyData);
}

testLiveParentLogin();
