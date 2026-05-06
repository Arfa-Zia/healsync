import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";
import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {defineString} from "firebase-functions/params";

admin.initializeApp();

const emailUser = defineString("EMAIL_USER");
const emailPass = defineString("EMAIL_PASS");

export const sendOTPEmail = onDocumentWritten(
  "otpCodes/{userId}",
  async (event) => {
    const data = event.data?.after.data();
    if (!data || data.used) return;

    const userId = event.params.userId;
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .get();

    const email = userDoc.data()?.email;
    if (!email) return;

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: emailUser.value(),
        pass: emailPass.value(),
      },
    });

    await transporter.sendMail({
      from: "HealSync <" + emailUser.value() + ">",
      to: email,
      subject: "Your HealSync Payment OTP",
      html: `<h2>Your OTP is: <strong>${data.code}</strong></h2>
             <p>Valid for 5 minutes. Do not share this code.</p>`,
    });
  }
);
