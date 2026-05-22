package com.Group10.Travel_trek

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.os.Bundle
import android.os.ParcelUuid
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val CHANNEL = "traveltrek.tourist/ble_advertise"
    private var advertiser: BluetoothLeAdvertiser? = null
    private var advertiseCallback: AdvertiseCallback? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAdvertising" -> {
                    val serviceUuidStr = call.argument<String>("serviceUuid")
                    val payload = call.argument<ByteArray>("payload")
                    val advertiseMode = call.argument<Int>("advertiseMode") ?: AdvertiseSettings.ADVERTISE_MODE_LOW_POWER
                    val txPowerLevel = call.argument<Int>("txPowerLevel") ?: AdvertiseSettings.ADVERTISE_TX_POWER_HIGH
                    val connectable = call.argument<Boolean>("connectable") ?: false

                    if (serviceUuidStr != null && payload != null) {
                        val success = startBleAdvertising(serviceUuidStr, payload, advertiseMode, txPowerLevel, connectable)
                        if (success) {
                            result.success(null)
                        } else {
                            result.error("BLE_ADVERTISE_ERROR", "Failed to start advertising", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "serviceUuid or payload is null", null)
                    }
                }
                "stopAdvertising" -> {
                    stopBleAdvertising()
                    result.success(null)
                }
                "getFreeStorage" -> {
                    try {
                        val stat = android.os.StatFs(filesDir.absolutePath)
                        val bytesAvailable = stat.availableBlocksLong * stat.blockSizeLong
                        result.success(bytesAvailable)
                    } catch (e: Exception) {
                        result.error("STORAGE_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startBleAdvertising(
        serviceUuidStr: String,
        payload: ByteArray,
        advertiseMode: Int,
        txPowerLevel: Int,
        connectable: Boolean
    ): Boolean {
        try {
            stopBleAdvertising() // stop previous if running

            val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            val adapter = bluetoothManager.adapter
            if (adapter == null || !adapter.isEnabled) {
                Log.e("MainActivity", "Bluetooth adapter is null or disabled")
                return false
            }

            advertiser = adapter.bluetoothLeAdvertiser
            if (advertiser == null) {
                Log.e("MainActivity", "Bluetooth LE advertiser not supported or null")
                return false
            }

            val settings = AdvertiseSettings.Builder()
                .setAdvertiseMode(advertiseMode)
                .setTxPowerLevel(txPowerLevel)
                .setConnectable(connectable)
                .build()

            val uuid = UUID.fromString(serviceUuidStr)
            val parcelUuid = ParcelUuid(uuid)

            val data = AdvertiseData.Builder()
                .addServiceData(parcelUuid, payload)
                .build()

            val callback = object : AdvertiseCallback() {
                override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                    super.onStartSuccess(settingsInEffect)
                    Log.i("MainActivity", "BLE advertising started successfully")
                }

                override fun onStartFailure(errorCode: Int) {
                    super.onStartFailure(errorCode)
                    Log.e("MainActivity", "BLE advertising failed with error: $errorCode")
                }
            }
            advertiseCallback = callback

            advertiser?.startAdvertising(settings, data, callback)
            return true
        } catch (e: Exception) {
            Log.e("MainActivity", "Error in startBleAdvertising", e)
            return false
        }
    }

    private fun stopBleAdvertising() {
        try {
            if (advertiser != null && advertiseCallback != null) {
                advertiser?.stopAdvertising(advertiseCallback)
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error stopping BLE advertising", e)
        } finally {
            advertiseCallback = null
            advertiser = null
        }
    }
}
