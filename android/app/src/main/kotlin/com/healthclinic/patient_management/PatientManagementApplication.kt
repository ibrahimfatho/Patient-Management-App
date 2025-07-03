package com.healthclinic.patient_management

import io.flutter.app.FlutterApplication
import com.google.firebase.FirebaseApp

class PatientManagementApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        // Initialize Firebase
        FirebaseApp.initializeApp(this)
    }
}
