package com.j4ck.j4ck_indooratlas

import android.content.Context
import android.os.Bundle
import android.os.Looper
import com.indooratlas.android.sdk.IALocation
import com.indooratlas.android.sdk.IALocationListener
import com.indooratlas.android.sdk.IALocationManager
import com.indooratlas.android.sdk.IALocationRequest
import com.indooratlas.android.sdk.IAOrientationListener
import com.indooratlas.android.sdk.IAOrientationRequest
import com.indooratlas.android.sdk.IARegion
import com.indooratlas.android.sdk.IAWayfindingListener
import com.indooratlas.android.sdk.IAGeofenceListener
import com.indooratlas.android.sdk.IAGeofenceEvent
import com.indooratlas.android.sdk.IAGeofenceRequest
import com.indooratlas.android.sdk.IAWayfindingRequest
import com.indooratlas.android.sdk.resources.IAFloorPlan
import com.indooratlas.android.sdk.resources.IALatLng

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class J4ckIndooratlasPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var locationEventChannel: EventChannel
    private lateinit var geofenceEventChannel: EventChannel
    private lateinit var orientationEventChannel: EventChannel
    private lateinit var wayfindingEventChannel: EventChannel
    private lateinit var mapEventChannel: EventChannel

    private lateinit var context: Context
    private var iaLocationManager: IALocationManager? = null

    @Volatile private var locationSink: EventChannel.EventSink? = null
    @Volatile private var geofenceSink: EventChannel.EventSink? = null
    @Volatile private var orientationSink: EventChannel.EventSink? = null
    @Volatile private var wayfindingSink: EventChannel.EventSink? = null
    @Volatile private var mapSink: EventChannel.EventSink? = null
    @Volatile private var lastFloorPlan: Map<String, Any?>? = null

    private val locationListener: IALocationListener = object : IALocationListener {
        override fun onLocationChanged(location: IALocation) {
            val payload: Map<String, Any?> = mapOf(
                "latitude" to location.latitude,
                "longitude" to location.longitude,
                "floorLevel" to location.floorLevel,
                "accuracy" to location.accuracy,
                "bearing" to location.bearing,
                "time" to location.time
            )
            locationSink?.success(payload)
        }

        override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {
            // Optional
        }
    }

    private val regionListener: IARegion.Listener = object : IARegion.Listener {
        override fun onEnterRegion(region: IARegion) {
            val payload: MutableMap<String, Any?> = mutableMapOf(
                "event" to "enter",
                "regionType" to region.type,
                "regionId" to region.id,
                "regionName" to region.name
            )
            region.floorPlan?.let { fp ->
                val fpMap = floorPlanToMap(fp)
                payload["floorPlan"] = fpMap
                lastFloorPlan = fpMap
                mapSink?.success(fpMap)
            }
            geofenceSink?.success(payload)
        }

        override fun onExitRegion(region: IARegion) {
            val payload: Map<String, Any?> = mapOf(
                "event" to "exit",
                "regionType" to region.type,
                "regionId" to region.id,
                "regionName" to region.name
            )
            geofenceSink?.success(payload)
        }
    }

    private fun floorPlanToMap(fp: IAFloorPlan): Map<String, Any?> {
        val matrix = try {
            fp.affineWgs2pix
        } catch (e: Throwable) {
            null
        }

        val wgsToPixel: List<Double>? = matrix?.let {
            val vals = FloatArray(9)
            try {
                it.getValues(vals)
                listOf(
                    vals[0].toDouble(), // a
                    vals[1].toDouble(), // b
                    vals[2].toDouble(), // c
                    vals[3].toDouble(), // d
                    vals[4].toDouble(), // e
                    vals[5].toDouble()  // f
                )
            } catch (_: Throwable) {
                null
            }
        }

        return mapOf(
            "id" to fp.id,
            "name" to fp.name,
            "url" to fp.url,
            "bitmapWidth" to fp.bitmapWidth,
            "bitmapHeight" to fp.bitmapHeight,
            "floorLevel" to fp.floorLevel,
            "widthMeters" to fp.widthMeters,
            "heightMeters" to fp.heightMeters,
            "pixelsToMeters" to fp.pixelsToMeters,
            "metersToPixels" to fp.metersToPixels,
            "bearing" to fp.bearing,
            "center" to latLngToMap(fp.center),
            "topLeft" to latLngToMap(fp.topLeft),
            "topRight" to latLngToMap(fp.topRight),
            "bottomLeft" to latLngToMap(fp.bottomLeft),
            "bottomRight" to latLngToMap(fp.bottomRight),
            "wgsToPixel" to wgsToPixel
        )
    }

    private fun latLngToMap(latLng: IALatLng?): Map<String, Any?>? {
        if (latLng == null) return null
        return mapOf(
            "latitude" to latLng.latitude,
            "longitude" to latLng.longitude
        )
    }

    private val geofenceListener: IAGeofenceListener = object : IAGeofenceListener {
        override fun onGeofencesTriggered(event: IAGeofenceEvent?) {
            if (event == null) return
            val triggeringGeofences = event.triggeringGeofences ?: emptyList()

            val triggeredList: List<Map<String, Any?>> = triggeringGeofences.map { gf ->
                mapOf(
                    "id" to gf.id,
                    "floor" to if (gf.hasFloor()) gf.floor else null,
                    "transitionType" to event.geofenceTransition
                )
            }

            val payload: Map<String, Any?> = mapOf(
                "eventType" to event.geofenceTransition,
                "triggered" to triggeredList
            )
            geofenceSink?.success(payload)
        }
    }

    private val orientationListener: IAOrientationListener = object : IAOrientationListener {
        override fun onHeadingChanged(timestamp: Long, heading: Double) {
            orientationSink?.success(mapOf("timestamp" to timestamp, "heading" to heading))
        }

        override fun onOrientationChange(timestamp: Long, quaternion: DoubleArray) {
            orientationSink?.success(mapOf("timestamp" to timestamp, "quaternion" to quaternion.toList()))
        }
    }

    private val wayfindingListener: IAWayfindingListener = IAWayfindingListener { route ->
        val legsList: List<Map<String, Any?>> = route.legs?.map { leg ->
            mapOf(
                "begin" to mapOf(
                    "lat" to leg.begin.latitude,
                    "lon" to leg.begin.longitude,
                    "floor" to leg.begin.floor
                ),
                "end" to mapOf(
                    "lat" to leg.end.latitude,
                    "lon" to leg.end.longitude,
                    "floor" to leg.end.floor
                ),
                "length" to leg.length,
                "direction" to leg.direction,
                "edgeIndex" to leg.edgeIndex
            )
        } ?: emptyList()

        val points: MutableList<Map<String, Double>> = ArrayList()
        route.legs?.let { legs ->
            if (legs.isNotEmpty()) {
                // add first begin
                points.add(mapOf("lat" to legs[0].begin.latitude, "lon" to legs[0].begin.longitude))
                for (i in legs.indices) {
                    // also add end of this leg
                    points.add(mapOf("lat" to legs[i].end.latitude, "lon" to legs[i].end.longitude))
                }
            }
        }

        wayfindingSink?.success(mapOf("legs" to legsList, "points" to points))
    }


    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, "j4ck_indooratlas/methods")
        methodChannel.setMethodCallHandler(this)

        locationEventChannel = EventChannel(binding.binaryMessenger, "j4ck_indooratlas/location")
        geofenceEventChannel = EventChannel(binding.binaryMessenger, "j4ck_indooratlas/geofence")
        orientationEventChannel = EventChannel(binding.binaryMessenger, "j4ck_indooratlas/orientation")
        wayfindingEventChannel = EventChannel(binding.binaryMessenger, "j4ck_indooratlas/wayfinding")
        mapEventChannel = EventChannel(binding.binaryMessenger, "j4ck_indooratlas/map")

        locationEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                locationSink = events
                startLocation()
            }
            override fun onCancel(arguments: Any?) {
                locationSink = null
                iaLocationManager?.removeLocationUpdates(locationListener)
            }
        })

        geofenceEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                geofenceSink = events
                iaLocationManager?.let { mgr ->
                    val req = IAGeofenceRequest.Builder()
                        .withCloudGeofences(true)
                        .build()
                    mgr.addGeofences(req, geofenceListener, Looper.getMainLooper())
                    mgr.registerRegionListener(regionListener)
                }
            }
            override fun onCancel(arguments: Any?) {
                geofenceSink = null
                iaLocationManager?.removeGeofenceUpdates(geofenceListener)
                iaLocationManager?.unregisterRegionListener(regionListener)
            }
        })

        mapEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                mapSink = events
            }
            override fun onCancel(arguments: Any?) {
                mapSink = null
            }
        })

        orientationEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                orientationSink = events
                iaLocationManager?.registerOrientationListener(IAOrientationRequest(10.0, 0.0), orientationListener)
            }
            override fun onCancel(arguments: Any?) {
                orientationSink = null
                iaLocationManager?.unregisterOrientationListener(orientationListener)
            }
        })

        wayfindingEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                wayfindingSink = events
            }
            override fun onCancel(arguments: Any?) {
                wayfindingSink = null
                iaLocationManager?.removeWayfindingUpdates()
            }
        })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initializeIndoorAtlas" -> {
                val apiKey: String? = call.argument("apiKey")
                if (apiKey.isNullOrBlank()) {
                    result.error("NO_API_KEY", "apiKey is required", null)
                    return
                }
                initialize(apiKey)
                result.success(mapOf("status" to "initialized"))
            }
            "startLocation" -> {
                startLocation()
                result.success(mapOf("status" to "location_started"))
            }
            "stopLocation" -> {
                iaLocationManager?.removeLocationUpdates(locationListener)
                result.success(mapOf("status" to "location_stopped"))
            }
            "startWayfinding" -> {
                val lat: Double? = call.argument("latitude")
                val lon: Double? = call.argument("longitude")
                val floor: Int? = call.argument("floor")
                if (lat == null || lon == null || floor == null) {
                    result.error("BAD_ARGS", "latitude, longitude and floor required", null)
                    return
                }
                startWayfinding(lat, lon, floor)
                result.success(mapOf("status" to "wayfinding_started"))
            }
            "stopWayfinding" -> {
                iaLocationManager?.removeWayfindingUpdates()
                result.success(mapOf("status" to "wayfinding_stopped"))
            }
            "getCurrentFloorPlan" -> {
                result.success(lastFloorPlan)
            }
            "dispose" -> {
                dispose()
                result.success(mapOf("status" to "disposed"))
            }
            else -> result.notImplemented()
        }
    }

    private fun initialize(apiKey: String) {
        val extras = Bundle(1).apply {
            putString(IALocationManager.EXTRA_API_KEY, apiKey)
        }
        iaLocationManager = IALocationManager.create(context, extras)
        iaLocationManager?.lockIndoors(true)
    }

    private fun startLocation() {
        if (iaLocationManager == null) return
        val locReq = IALocationRequest.create()
        try {
            locReq.priority = IALocationRequest.PRIORITY_CART_MODE
        } catch (_: Throwable) {}
        iaLocationManager?.requestLocationUpdates(locReq, locationListener, Looper.getMainLooper())
    }

    private fun startWayfinding(latitude: Double, longitude: Double, floor: Int) {
        val req = IAWayfindingRequest.Builder()
            .withLatitude(latitude)
            .withLongitude(longitude)
            .withFloor(floor)
            .build()
        iaLocationManager?.requestWayfindingUpdates(req, wayfindingListener, Looper.getMainLooper())
    }

    private fun dispose() {
        try { iaLocationManager?.removeLocationUpdates(locationListener) } catch (_: Throwable) {}
        try { iaLocationManager?.removeGeofenceUpdates(geofenceListener) } catch (_: Throwable) {}
        try { iaLocationManager?.removeWayfindingUpdates() } catch (_: Throwable) {}
        try { iaLocationManager?.unregisterOrientationListener(orientationListener) } catch (_: Throwable) {}
        try { iaLocationManager?.unregisterRegionListener(regionListener) } catch (_: Throwable) {}
        try { iaLocationManager?.destroy() } catch (_: Throwable) {}
        iaLocationManager = null

        locationSink = null
        geofenceSink = null
        orientationSink = null
        wayfindingSink = null
        mapSink = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        locationEventChannel.setStreamHandler(null)
        geofenceEventChannel.setStreamHandler(null)
        orientationEventChannel.setStreamHandler(null)
        wayfindingEventChannel.setStreamHandler(null)
        mapEventChannel.setStreamHandler(null)
        dispose()
    }
}
