import { contactDetails as defaultContactDetails } from "../models/contact.js";

export function useContact(contactDetails = defaultContactDetails) {
  const openWhatsApp = (message) => {
    const url = new URL(`https://wa.me/${contactDetails.whatsapp}`);
    url.searchParams.set("text", message);
    window.open(url.toString(), "_blank", "noopener,noreferrer");
  };

  const enquireAboutCraft = (craftName) => {
    openWhatsApp(
      `Hello Seithati Weavers, I am interested in your ${craftName}. Could you please share more information?`,
    );
  };

  const sendEnquiry = (event) => {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);
    const name = String(formData.get("name") ?? "").trim();
    const senderEmail = String(formData.get("email") ?? "").trim();
    const subject = String(formData.get("subject") ?? "").trim();
    const message = String(formData.get("message") ?? "").trim();

    if (!name || !senderEmail || !message) {
      return;
    }

    const body = [
      `Name: ${name}`,
      `Email: ${senderEmail}`,
      `Interest: ${subject}`,
      "",
      "Message:",
      message,
    ].join("\n");

    const mailto = new URL(`mailto:${contactDetails.email}`);
    mailto.searchParams.set("subject", `Website enquiry: ${subject}`);
    mailto.searchParams.set("body", body);
    window.location.href = mailto.toString();
  };

  return { enquireAboutCraft, openWhatsApp, sendEnquiry };
}
