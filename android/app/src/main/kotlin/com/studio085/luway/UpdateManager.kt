package com.studio085.luway

import android.app.Activity
import android.content.Intent
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.plugin.common.MethodChannel

/**
 * This class handles app updates using the Google Play Core library.
 * It should be used after properly adding the Play Core dependency to your build.gradle.kts file.
 */
class UpdateManager(private val activity: Activity) {
    private val appUpdateManager: AppUpdateManager = AppUpdateManagerFactory.create(activity)
    private val REQUEST_CODE_UPDATE = 100

    fun checkForUpdate(result: MethodChannel.Result) {
        try {
            val appUpdateInfoTask = appUpdateManager.appUpdateInfo
            appUpdateInfoTask.addOnSuccessListener { appUpdateInfo ->
                val updateAvailable = appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
                        appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)
                result.success(updateAvailable)
            }.addOnFailureListener { e ->
                result.error("UPDATE_CHECK_FAILED", e.message, null)
            }
        } catch (e: Exception) {
            result.error("UPDATE_CHECK_ERROR", e.message, null)
        }
    }

    fun startUpdate(result: MethodChannel.Result) {
        try {
            val appUpdateInfoTask = appUpdateManager.appUpdateInfo
            appUpdateInfoTask.addOnSuccessListener { appUpdateInfo ->
                if (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
                        appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)) {
                    try {
                        appUpdateManager.startUpdateFlowForResult(
                            appUpdateInfo,
                            AppUpdateType.FLEXIBLE,
                            activity,
                            REQUEST_CODE_UPDATE
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UPDATE_FLOW_FAILED", e.message, null)
                    }
                } else {
                    result.success(false)
                }
            }.addOnFailureListener { e ->
                result.error("UPDATE_START_FAILED", e.message, null)
            }
        } catch (e: Exception) {
            result.error("UPDATE_START_ERROR", e.message, null)
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_CODE_UPDATE) {
            if (resultCode != Activity.RESULT_OK) {
                // Update flow failed or was cancelled
            }
        }
    }

    fun resumeUpdates() {
        appUpdateManager.appUpdateInfo.addOnSuccessListener { appUpdateInfo ->
            if (appUpdateInfo.installStatus() == InstallStatus.DOWNLOADED) {
                // App update has been downloaded, prompt user to complete installation
                appUpdateManager.completeUpdate()
            }
        }
    }
}
