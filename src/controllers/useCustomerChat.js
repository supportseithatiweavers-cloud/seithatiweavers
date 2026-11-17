import { useEffect, useMemo, useState } from "react";
import {
  addDoc,
  collection,
  doc,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
} from "firebase/firestore";
import {
  GoogleAuthProvider,
  onAuthStateChanged,
  signInWithPopup,
  signOut,
} from "firebase/auth";
import { auth, db } from "../firebase.js";

const maxImageSize = 10 * 1024 * 1024;
const allowedImageTypes = new Set(["image/jpeg", "image/png", "image/webp"]);
const mediaApiUrl = import.meta.env.VITE_MEDIA_API_URL;

export function useCustomerChat(user) {
  const [messages, setMessages] = useState([]);
  const [chatStatus, setChatStatus] = useState("idle");
  const [chatError, setChatError] = useState("");

  const room = useMemo(() => (user?.uid ? `customer-${user.uid}` : null), [user?.uid]);

  useEffect(() => {
    if (!db || !room) {
      setMessages([]);
      return undefined;
    }

    const messagesQuery = query(
      collection(db, "customerChats", room, "messages"),
      orderBy("createdAt", "asc"),
    );

    return onSnapshot(
      messagesQuery,
      (snapshot) => {
        setMessages(snapshot.docs.map((message) => ({
          id: message.id,
          ...message.data(),
        })));
        setChatError("");
      },
      (error) => {
        console.error("Could not load customer chat messages.", error);
        setChatError("Unable to load chat messages right now.");
      },
    );
  }, [room]);

  const sendMessage = async (text, imageFile = null) => {
    if (!db || !auth || !user || !room || (!text.trim() && !imageFile)) {
      return false;
    }
    if (imageFile) {
      if (!mediaApiUrl) {
        setChatError("Image uploads are not configured. Please contact us directly.");
        return false;
      }
      if (!allowedImageTypes.has(imageFile.type) || imageFile.size > maxImageSize) {
        setChatError("Choose a JPEG, PNG, or WebP image up to 10 MB.");
        return false;
      }
    }

    try {
      setChatStatus("sending");
      setChatError("");

      const roomRef = doc(db, "customerChats", room);
      await setDoc(roomRef, {
        uid: user.uid,
        customerName: user.displayName || "",
        customerEmail: user.email || "",
        updatedAt: serverTimestamp(),
      }, { merge: true });

      let imageUrl = "";
      let imageName = "";
      if (imageFile) {
        const token = await auth.currentUser?.getIdToken();
        if (!token) throw new Error("Sign in again before uploading an image.");

        const formData = new FormData();
        formData.append("file", imageFile, imageFile.name);
        const response = await fetch(new URL("/chat-upload", mediaApiUrl), {
          method: "POST",
          headers: { Authorization: `Bearer ${token}` },
          body: formData,
        });
        const result = await response.json();
        if (!response.ok) {
          throw new Error(result.error || "Image upload failed.");
        }
        imageUrl = result.url;
        imageName = imageFile.name;
      }

      await addDoc(collection(roomRef, "messages"), {
        sender: "customer",
        senderId: user.uid,
        senderName: user.displayName || user.email || "Customer",
        text: text.trim(),
        ...(imageUrl ? { imageUrl, imageName } : {}),
        createdAt: serverTimestamp(),
      });
      setChatStatus("sent");
      return true;
    } catch (error) {
      console.error("Could not send customer chat message.", error);
      setChatError("Your message could not be sent. Please try again.");
      setChatStatus("error");
      return false;
    }
  };

  return { chatError, chatStatus, messages, room, sendMessage };
}

export function useAdminPresence() {
  const [presence, setPresence] = useState(null);
  const [loading, setLoading] = useState(true);
  const [available, setAvailable] = useState(true);
  const [now, setNow] = useState(Date.now());

  useEffect(() => {
    if (!db) {
      setLoading(false);
      setAvailable(false);
      return undefined;
    }

    return onSnapshot(
      doc(db, "site", "adminPresence"),
      (snapshot) => {
        setPresence(snapshot.exists() ? snapshot.data() : null);
        setLoading(false);
        setAvailable(true);
      },
      (error) => {
        console.error("Could not load admin availability.", error);
        setLoading(false);
        setAvailable(false);
      },
    );
  }, []);

  useEffect(() => {
    const timer = window.setInterval(() => setNow(Date.now()), 30_000);
    return () => window.clearInterval(timer);
  }, []);

  const updatedAt = presence?.updatedAt?.toDate?.().getTime?.();
  const online =
    presence?.online === true &&
    typeof updatedAt === "number" &&
    now - updatedAt <= 90_000;

  return {
    available,
    loading,
    online,
    profileName:
      typeof presence?.profileName === "string" && presence.profileName.trim()
        ? presence.profileName.trim()
        : "Seithati Weavers",
    profileImageUrl:
      typeof presence?.profileImageUrl === "string"
        ? presence.profileImageUrl
        : "",
  };
}

export function useCustomerAuth() {
  const [authState, setAuthState] = useState({
    user: null,
    loading: true,
    authenticating: false,
    error: "",
  });

  useEffect(() => {
    if (!auth) {
      setAuthState({
        user: null,
        loading: false,
        authenticating: false,
        error: "Authentication is unavailable.",
      });
      return undefined;
    }

    return onAuthStateChanged(
      auth,
      (user) => setAuthState({
        user,
        loading: false,
        authenticating: false,
        error: "",
      }),
      (error) => {
        console.error("Could not resolve customer authentication state.", error);
        setAuthState({
          user: null,
          loading: false,
          authenticating: false,
          error: "Unable to check your sign-in status.",
        });
      },
    );
  }, []);

  const signInWithGoogle = async () => {
    if (!auth) {
      return { success: false, message: "Authentication is unavailable." };
    }

    setAuthState((current) => ({ ...current, authenticating: true, error: "" }));
    try {
      const provider = new GoogleAuthProvider();
      provider.setCustomParameters({ prompt: "select_account" });
      await signInWithPopup(auth, provider);
      return { success: true };
    } catch (error) {
      console.error("Could not sign in customer with Google.", error);
      setAuthState((current) => ({ ...current, authenticating: false }));
      return {
        success: false,
        message: error.message || "We could not sign you in with Google.",
      };
    }
  };

  const logOut = async () => {
    if (auth) await signOut(auth);
  };

  return { ...authState, logOut, signInWithGoogle };
}
