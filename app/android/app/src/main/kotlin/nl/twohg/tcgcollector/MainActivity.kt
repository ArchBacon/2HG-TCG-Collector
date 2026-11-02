package nl.twohg.tcgcollector

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    /**
     * The channels the API's notifications use (its channel_id): "wishlist" for wishlist cards in
     * stock, "news" for the admin's announcements. Users see their names in the app's notification
     * settings and can turn each off there. Creating them again is harmless.
     */
    private fun createNotificationChannels() {
        val wishlist = NotificationChannel("wishlist", "Wishlist cards in store", NotificationManager.IMPORTANCE_DEFAULT)
        wishlist.description = "When a card on your wishlist comes into stock at 2HG"
        val news = NotificationChannel("news", "News and events", NotificationManager.IMPORTANCE_DEFAULT)
        news.description = "Events, new sets and offers from 2HG"
        getSystemService(NotificationManager::class.java).createNotificationChannels(listOf(wishlist, news))
    }
}
