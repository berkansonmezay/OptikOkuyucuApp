import { initializeApp } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js";
import { getFirestore, collection, addDoc, getDocs, getDoc, doc, updateDoc, deleteDoc, setDoc, query, where, limit } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";

const firebaseConfig = {
    apiKey: "AIzaSyANTnM-NUxwddhGA7uN_offVxFuah5F7HE",
    authDomain: "optik-okuyucu-app.firebaseapp.com",
    projectId: "optik-okuyucu-app",
    storageBucket: "optik-okuyucu-app.firebasestorage.app",
    messagingSenderId: "5981672912",
    appId: "1:5981672912:web:22acc40ec3706a7c9355d5"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

const VERSION = "3.2"; // Cache bust version
console.log(`[OptikApp v${VERSION}] Firebase initialized.`);

// Helper functions for Exams
export async function saveExam(examData) {
    try {
        const currentUser = getCurrentUser();

        if (examData.id && typeof examData.id === 'string' && examData.id.trim() !== '') {
            // Update existing exam
            const existingExam = await getExamById(examData.id); // This already checks ownership
            if (!existingExam) {
                throw new Error("Sınavı düzenleme yetkiniz yok veya sınav bulunamadı.");
            }
            const docRef = doc(db, "exams", examData.id);
            await updateDoc(docRef, examData);
            return examData.id;
        } else {
            // Create new exam
            // Don't save empty string ids to firestore as document ids, let it auto generate
            if (examData.id === '') delete examData.id;

            const newExam = {
                ...examData,
                createdAt: new Date().toISOString()
            };

            // Associate with current user if logged in
            if (currentUser && currentUser.id) {
                newExam.creatorId = currentUser.id;
            }

            const docRef = await addDoc(collection(db, "exams"), newExam);
            return docRef.id;
        }
    } catch (e) {
        console.error("Error saving exam: ", e);
        throw e;
    }
}

export async function getExams(userId = null) {
    try {
        const currentUser = getCurrentUser();
        console.log(`[v${VERSION}] getExams called. userId param:`, userId, "Session User:", currentUser ? currentUser.id : "null");

        let q;

        // Determine filter. If userId is passed, use it. 
        // If not passed and NOT admin, use currentUser.id.
        // If admin and no userId passed, show everything.
        let filterId = userId;
        if (!filterId && currentUser && currentUser.role !== 'admin') {
            filterId = currentUser.id;
        }

        if (filterId) {
            console.log(`[v${VERSION}] Fetching exams for creatorId: "${filterId}"`);
            q = query(collection(db, "exams"), where("creatorId", "==", filterId));
        } else {
            console.log(`[v${VERSION}] Fetching all exams (Admin or Unauthenticated)`);
            q = collection(db, "exams");
        }

        const querySnapshot = await getDocs(q);
        const exams = [];
        querySnapshot.forEach((doc) => {
            const data = doc.data();
            exams.push({ id: doc.id, ...data });
        });

        console.log(`[v${VERSION}] Firestore returned ${exams.length} exams.`);

        // Sort by date (newest first), then by createdAt as a fallback
        return exams.sort((a, b) => {
            const parseDate = (dateStr) => {
                if (!dateStr) return 0;
                // If the date contains '-', it's likely YYYY-MM-DD
                if (dateStr.includes('-')) {
                    const [y, m, d] = dateStr.split('-');
                    return new Date(y, m - 1, d).getTime();
                }
                return new Date(dateStr).getTime();
            };

            const dateA = parseDate(a.date);
            const dateB = parseDate(b.date);

            if (dateA !== dateB) {
                return dateB - dateA; // Newest date first
            }

            // If dates are identical (or both missing), fallback to createdAt
            const createdA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
            const createdB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
            return createdB - createdA;
        });
    } catch (e) {
        console.error("Error getting exams: ", e);
        return [];
    }
}

export async function deleteExam(examId) {
    try {
        const currentUser = getCurrentUser();
        const exam = await getExamById(examId);

        if (!exam) return false;

        // Check ownership
        if (currentUser.role !== 'admin' && exam.creatorId !== currentUser.id) {
            console.error("Unauthorized delete attempt");
            return false;
        }

        await deleteDoc(doc(db, "exams", examId));
        return true;
    } catch (e) {
        console.error("Error deleting exam: ", e);
        return false;
    }
}

export async function getExamById(examId) {
    try {
        const currentUser = getCurrentUser();
        const docRef = doc(db, "exams", examId);
        const docSnap = await getDoc(docRef);

        if (docSnap.exists()) {
            const examData = { id: docSnap.id, ...docSnap.data() };

            // Ownership check
            if (currentUser && currentUser.role !== 'admin' && examData.creatorId !== currentUser.id) {
                console.warn("[v2] Access denied to exam which belongs to someone else.");
                return null;
            }

            return examData;
        } else {
            return null;
        }
    } catch (e) {
        console.error("Error getting exam: ", e);
        return null;
    }
}

// Student Results inside an Exam
export async function addStudentResult(examId, resultData) {
    try {
        const currentUser = getCurrentUser();
        const exam = await getExamById(examId);

        if (!exam) throw new Error("Sınava erişim yetkiniz yok veya sınav bulunamadı.");

        // Check for existing result for this student in this exam to prevent duplicates
        const resultsRef = collection(db, "exams", examId, "results");
        const q = query(resultsRef, where("studentNo", "==", resultData.studentNo), limit(1));
        const querySnapshot = await getDocs(q);

        let docId;
        let isNew = false;

        if (!querySnapshot.empty) {
            // Update existing result
            docId = querySnapshot.docs[0].id;
            const docRef = doc(db, "exams", examId, "results", docId);
            await updateDoc(docRef, {
                ...resultData,
                updatedAt: new Date().toISOString()
            });
        } else {
            // Create new result
            const docRef = await addDoc(resultsRef, {
                ...resultData,
                createdAt: new Date().toISOString()
            });
            docId = docRef.id;
            isNew = true;
        }

        // Update the student count on the main exam document only for new students
        if (isNew) {
            const examDoc = doc(db, "exams", examId);
            await updateDoc(examDoc, { studentCount: (exam.studentCount || 0) + 1 });
        }

        return docId;
    } catch (e) {
        console.error("Error saving student result: ", e);
        throw e;
    }
}

export async function getStudentResults(examId) {
    try {
        const exam = await getExamById(examId); // This already checks ownership
        if (!exam) return [];

        const querySnapshot = await getDocs(collection(db, "exams", examId, "results"));
        const results = [];
        querySnapshot.forEach((doc) => {
            results.push({ id: doc.id, ...doc.data() });
        });
        return results;
    } catch (e) {
        console.error("Error getting student results: ", e);
        return [];
    }
}

// Authentication and User Management
export async function loginUser(username, password) {
    try {
        console.log("[v2] Firebase loginUser starting for:", username);
        const usersRef = collection(db, "users");

        // --- ENSURE DEFAULT USERS EXIST (FOR TESTING) ---
        console.log("[v2] Checking if default admin exists...");
        const adminCheck = await getDocs(query(usersRef, where("username", "==", "admin"), limit(1)));
        if (adminCheck.empty) {
            console.log("Admin account missing. Creating default admin/123.");
            await addDoc(usersRef, { username: "admin", password: "123", role: "admin", name: "Sistem Yöneticisi" });
        } else {
            // Ensure existing admin HAS the role field
            const adminDoc = adminCheck.docs[0];
            if (adminDoc.data().role !== 'admin') {
                console.log("Fixing existing admin role...");
                await updateDoc(doc(db, "users", adminDoc.id), { role: "admin" });
            }
        }

        const kurumCheck = await getDocs(query(usersRef, where("username", "==", "kurum"), limit(1)));
        if (kurumCheck.empty) {
            console.log("Kurum account missing. Creating default kurum/123.");
            await addDoc(usersRef, { username: "kurum", password: "123", role: "institution", name: "Test Kurumu" });
        }
        // --------------------------------------------------

        // Query for username and password
        console.log("Executing Firestore query for user...");
        const q = query(usersRef, where("username", "==", username), where("password", "==", password));
        const querySnapshot = await getDocs(q);
        console.log("Query complete. Found docs:", querySnapshot.size);

        if (!querySnapshot.empty) {
            // User found
            const userDoc = querySnapshot.docs[0];
            const userData = userDoc.data();
            console.log("User found:", userData.username, "Role:", userData.role);

            // Save non-sensitive user data to localStorage (Session)
            const sessionData = {
                id: userDoc.id,
                username: userData.username,
                role: userData.role,
                name: userData.name
            };
            localStorage.setItem('currentUser', JSON.stringify(sessionData));

            return { success: true, user: sessionData };
        } else {
            console.log("No matching user found in Firestore.");
            return { success: false, message: "Kullanıcı adı veya şifre hatalı." };
        }
    } catch (e) {
        console.error("Giriş hatası (Firestore):", e);
        return { success: false, message: "Bağlantı hatası oluştu." };
    }
}

export function getCurrentUser() {
    const userStr = localStorage.getItem('currentUser');
    if (userStr) {
        try {
            const user = JSON.parse(userStr);
            // console.log(`[v${VERSION}] User found in session:`, user.username);
            return user;
        } catch (e) {
            console.error(`[v${VERSION}] Session Parse Error:`, e);
            return null;
        }
    }
    console.warn(`[v${VERSION}] No user found in localStorage.`);
    return null;
}

export function logoutUser() {
    localStorage.removeItem('currentUser');
}

export async function saveUserProfile(profileData) {
    const currentUser = getCurrentUser();
    if (!currentUser) return false;

    try {
        const docRef = doc(db, "users", currentUser.id);
        await setDoc(docRef, profileData, { merge: true });

        // Update local session if name changes
        if (profileData.name) {
            currentUser.name = profileData.name;
            localStorage.setItem('currentUser', JSON.stringify(currentUser));
        }
        return true;
    } catch (e) {
        console.error("Error saving profile: ", e);
        return false;
    }
}

export async function getUserProfile() {
    const currentUser = getCurrentUser();
    if (!currentUser) return null;

    try {
        const docRef = doc(db, "users", currentUser.id);
        const docSnap = await getDoc(docRef);
        if (docSnap.exists()) {
            return docSnap.data();
        } else {
            // Default profile if none exists
            const defaultProfile = {
                username: currentUser.username,
                role: currentUser.role,
                name: currentUser.name || 'İsimsiz Kullanıcı',
                institution: 'Bilinmiyor',
                profileImageUrl: ''
            };
            return defaultProfile;
        }
    } catch (e) {
        console.error("Error getting profile: ", e);
        return null;
    }
}

export async function addInstitutionUser(username, password, name) {
    try {
        const usersRef = collection(db, "users");

        // Check if username exists
        const q = query(usersRef, where("username", "==", username));
        const snapshot = await getDocs(q);

        if (!snapshot.empty) {
            return { success: false, message: "Bu kullanıcı adı zaten mevcut!" };
        }

        // Create user
        await addDoc(usersRef, {
            username: username,
            password: password,
            role: "institution",
            name: name || "İsimsiz Kurum"
        });

        return { success: true };
    } catch (e) {
        console.error("Error adding institution user:", e);
        return { success: false, message: "Bağlantı hatası oluştu." };
    }
}

export async function getAllInstitutions() {
    try {
        const usersRef = collection(db, "users");
        const q = query(usersRef, where("role", "==", "institution"));
        const snapshot = await getDocs(q);
        return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (e) {
        console.error("Error getting institutions:", e);
        return [];
    }
}

export async function updateInstitution(id, data) {
    try {
        const docRef = doc(db, "users", id);
        await updateDoc(docRef, data);
        return { success: true };
    } catch (e) {
        console.error("Error updating institution:", e);
        return { success: false, message: e.message };
    }
}

export async function deleteInstitution(id) {
    try {
        const docRef = doc(db, "users", id);
        await deleteDoc(docRef);
        return { success: true };
    } catch (e) {
        console.error("Error deleting institution:", e);
        return { success: false, message: e.message };
    }
}
