import { useEffect, useState } from "react";
import { doc, onSnapshot } from "firebase/firestore";
import { db } from "../firebase.js";
import { contactDetails } from "../models/contact.js";
import { crafts } from "../models/crafts.js";
import { translations } from "../translations.js";

const fallbackContent = {
  translations,
  crafts,
  contact: contactDetails,
  images: {},
};

function mergeObjects(base, override) {
  if (!override || typeof override !== "object" || Array.isArray(override)) {
    return override ?? base;
  }

  return Object.entries(override).reduce(
    (result, [key, value]) => ({
      ...result,
      [key]:
        value && typeof value === "object" && !Array.isArray(value)
          ? mergeObjects(base?.[key], value)
          : value,
    }),
    { ...base },
  );
}

function mergeCrafts(remote = {}) {
  const overrides = remote.craftOverrides ?? {};
  const updates = new Map(
    Object.entries(overrides).map(([id, value]) => [id, value]),
  );
  const existingIds = new Set(crafts.map((craft) => craft.id));
  const merged = crafts.map((craft) => ({
    ...craft,
    ...(updates.get(craft.id) ?? {}),
  }));

  Object.entries(overrides)
    .filter(([id]) => !existingIds.has(id))
    .forEach(([, craft]) => merged.push(craft));

  if (Array.isArray(remote.newCrafts)) merged.push(...remote.newCrafts);
  return merged;
}

export function useSiteContent() {
  const [content, setContent] = useState(fallbackContent);

  useEffect(() => {
    if (!db) return undefined;

    return onSnapshot(
      doc(db, "site", "content"),
      (snapshot) => {
        const remote = snapshot.data() ?? {};
        const merged = mergeObjects(fallbackContent, remote);
        const remoteContact = remote.contact ?? {};
        const isOldPhone = (value) =>
          String(value ?? "").replace(/\D/g, "") === "2663315077";
        setContent({
          ...merged,
          contact: {
            ...merged.contact,
            phone: isOldPhone(remoteContact.phone)
              ? contactDetails.phone
              : merged.contact.phone,
            secondaryPhone:
              remoteContact.secondaryPhone ?? contactDetails.secondaryPhone,
            whatsapp: isOldPhone(remoteContact.whatsapp)
              ? contactDetails.whatsapp
              : merged.contact.whatsapp,
          },
          crafts: mergeCrafts(remote),
        });
      },
      (error) => {
        console.error("Could not load live website content from Firestore.", error);
      },
    );
  }, []);

  return content;
}
