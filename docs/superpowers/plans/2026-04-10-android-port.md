# BudgyByDarskie Android Port — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the BudgyByDarskie iOS finance tracking app to Android with full feature parity, sharing the same Firebase backend.

**Architecture:** Kotlin + Jetpack Compose, MVVM with Repository pattern. Hilt for DI, Coroutines + Flow for async, Navigation Compose for routing. Same Firestore collections/schema as iOS.

**Tech Stack:** Kotlin, Jetpack Compose, Material Design 3, Hilt, Firebase Auth + Firestore, Google Sign-In, Vico Charts, ML Kit OCR, WorkManager, DataStore.

---

## Phase 1: Project Scaffold & Configuration

### Task 1: Create Android Project

**Files:**
- Create: `/Users/daryll/Desktop/BudgyByDarskieAndroid/` (entire project via Android CLI)

- [ ] **Step 1: Generate project skeleton**

```bash
mkdir -p /Users/daryll/Desktop/BudgyByDarskieAndroid
cd /Users/daryll/Desktop/BudgyByDarskieAndroid
git init
```

Then create the project structure manually since we're not using Android Studio interactively. Create the Gradle wrapper and project files:

- [ ] **Step 2: Create settings.gradle.kts**

```kotlin
// settings.gradle.kts
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolution {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "BudgyByDarskie"
include(":app")
```

- [ ] **Step 3: Create root build.gradle.kts**

```kotlin
// build.gradle.kts (root)
plugins {
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.1.0" apply false
    id("com.google.dagger.hilt.android") version "2.51" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

- [ ] **Step 4: Create app/build.gradle.kts with all dependencies**

```kotlin
// app/build.gradle.kts
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("com.google.dagger.hilt.android")
    id("com.google.gms.google-services")
    kotlin("kapt")
}

android {
    namespace = "com.darskie.budgybydarskie"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.darskie.budgybydarskie"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }
}

dependencies {
    // Firebase BOM
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")

    // Google Sign-In (Credential Manager)
    implementation("com.google.android.gms:play-services-auth:21.3.0")
    implementation("androidx.credentials:credentials:1.3.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.3.0")
    implementation("com.google.android.libraries.identity.googleid:googleid:1.1.1")

    // Jetpack Compose BOM
    implementation(platform("androidx.compose:compose-bom:2024.12.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.activity:activity-compose:1.9.3")
    implementation("androidx.navigation:navigation-compose:2.8.5")

    // Hilt
    implementation("com.google.dagger:hilt-android:2.51")
    kapt("com.google.dagger:hilt-compiler:2.51")
    implementation("androidx.hilt:hilt-navigation-compose:1.2.0")

    // Lifecycle + ViewModel
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.7")

    // Vico Charts
    implementation("com.patrykandpatrick.vico:compose-m3:2.0.0-beta.3")

    // ML Kit OCR
    implementation("com.google.mlkit:text-recognition:16.0.1")

    // WorkManager
    implementation("androidx.work:work-runtime-ktx:2.10.0")

    // DataStore
    implementation("androidx.datastore:datastore-preferences:1.1.1")

    // Coil (image loading)
    implementation("io.coil-kt:coil-compose:2.7.0")

    // OkHttp (API calls)
    implementation("com.squareup.okhttp3:okhttp:4.12.0")

    // Testing
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.9.0")
    testImplementation("io.mockk:mockk:1.13.13")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}

kapt {
    correctErrorTypes = true
}
```

- [ ] **Step 5: Create AndroidManifest.xml**

```xml
<!-- app/src/main/AndroidManifest.xml -->
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.VIBRATE" />

    <application
        android:name=".BudgyApp"
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="Budgy"
        android:supportsRtl="true"
        android:theme="@style/Theme.BudgyByDarskie">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="budgy" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

- [ ] **Step 6: Create Gradle wrapper files**

Download and set up gradle wrapper (8.9):

```bash
cd /Users/daryll/Desktop/BudgyByDarskieAndroid
gradle wrapper --gradle-version 8.9
```

Or create `gradle/wrapper/gradle-wrapper.properties`:

```properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.9-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
```

- [ ] **Step 7: Add google-services.json**

Copy `google-services.json` from the Firebase console (same project as iOS) into `app/google-services.json`. The user must download this from Firebase Console > Project Settings > Android app (add one with package `com.darskie.budgybydarskie` if not yet added).

- [ ] **Step 8: Create .gitignore and commit**

```gitignore
*.iml
.gradle
/local.properties
/.idea
.DS_Store
/build
/captures
.externalNativeBuild
.cxx
local.properties
google-services.json
```

```bash
git add -A
git commit -m "feat: initial Android project scaffold with all dependencies"
```

---

## Phase 2: Data Models & Enums

### Task 2: Create All Enums

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/model/Enums.kt`

- [ ] **Step 1: Create Enums.kt with all enum types**

```kotlin
package com.darskie.budgybydarskie.data.model

import androidx.compose.ui.graphics.Color

// Wallet Type
enum class WalletType(val label: String) {
    bank("Bank"),
    cash("Cash");

    companion object {
        fun fromString(value: String): WalletType =
            entries.firstOrNull { it.name == value } ?: bank
    }
}

// Expense Category
enum class ExpenseCategory(
    val label: String,
    val color: Color,
    val icon: String
) {
    food("Food", Color(0xFFFF9800), "restaurant"),
    transport("Transport", Color(0xFF2196F3), "directions_car"),
    utilities("Utilities", Color(0xFFFFEB3B), "bolt"),
    shopping("Shopping", Color(0xFFE91E63), "shopping_bag"),
    entertainment("Entertainment", Color(0xFF9C27B0), "sports_esports"),
    health("Health", Color(0xFFF44336), "favorite"),
    other("Other", Color(0xFF9E9E9E), "more_horiz");

    companion object {
        fun fromString(value: String): ExpenseCategory =
            entries.firstOrNull { it.name == value } ?: other
    }
}

// Investment Type
enum class InvestmentType(val label: String, val color: Color) {
    stock("Stock", Color(0xFF9C27B0)),
    crypto("Crypto", Color(0xFFFF9800)),
    other("Other", Color(0xFF2196F3));

    companion object {
        fun fromString(value: String): InvestmentType =
            entries.firstOrNull { it.name == value } ?: other
    }
}

// Investment Source
enum class InvestmentSource(val label: String) {
    salary("Salary"),
    buySellProfits("Buy & Sell Profits"),
    oldSavings("Old Savings");

    companion object {
        fun fromString(value: String): InvestmentSource =
            entries.firstOrNull { it.name == value } ?: salary
    }
}

// Asset Category
enum class AssetCategory(
    val label: String,
    val icon: String,
    val color: Color
) {
    cellphone("Cellphone", "smartphone", Color(0xFF2196F3)),
    laptop("Laptop", "laptop", Color(0xFF9C27B0)),
    tablet("Tablet", "tablet", Color(0xFF4CAF50)),
    accessory("Accessory", "watch", Color(0xFFFF9800)),
    other("Other", "more_horiz", Color(0xFF9E9E9E));

    companion object {
        fun fromString(value: String): AssetCategory =
            entries.firstOrNull { it.name == value } ?: other
    }
}

// Item Type (Buy & Sell)
enum class ItemType(val label: String, val color: Color) {
    phone("Phone", Color(0xFF9C27B0)),
    laptop("Laptop", Color(0xFF2196F3)),
    tablet("Tablet", Color(0xFF4CAF50)),
    accessory("Accessory", Color(0xFFFF9800)),
    other("Other", Color(0xFF9E9E9E));

    companion object {
        fun fromString(value: String): ItemType =
            entries.firstOrNull { it.name == value } ?: other
    }
}

// Buy & Sell Status
enum class BuySellStatus(val label: String, val color: Color) {
    available("Available", Color(0xFF2196F3)),
    pending("Pending", Color(0xFFFF9800)),
    sold("Sold", Color(0xFF4CAF50));

    companion object {
        fun fromString(value: String): BuySellStatus =
            entries.firstOrNull { it.name == value } ?: available
    }
}

// Deposit Source
enum class DepositSource(val label: String) {
    salary("Salary"),
    milestone("Milestone"),
    buySellProfit("Buy & Sell Profit"),
    oldSavings("Old Savings"),
    other("Other");

    companion object {
        fun fromString(value: String): DepositSource =
            entries.firstOrNull { it.name == value } ?: other
    }
}

// Wallet Transaction Type
enum class WalletTransactionType(
    val label: String,
    val icon: String,
    val isInflow: Boolean
) {
    deposit("Deposit", "arrow_downward", true),
    expense("Expense", "arrow_upward", false),
    withdrawal("Transfer Out", "swap_horiz", false),
    withdrawalIn("Transfer In", "arrow_downward", true),
    investment("Investment", "trending_up", false),
    investmentExit("TP/SL", "arrow_downward", true),
    buySell("Buy & Sell", "sync_alt", false),
    buySellIn("Buy & Sell (Sold)", "arrow_downward", true),
    receivablePayment("Receivable Payment", "arrow_downward", true),
    receivable("Receivable", "person", false),
    asset("Asset", "inventory_2", false);
}

// Activity Log Type
enum class ActivityLogType(
    val label: String,
    val icon: String,
    val color: Color
) {
    expense("Expense", "receipt_long", Color(0xFFF44336)),
    investment("Investment", "trending_up", Color(0xFF9C27B0)),
    deposit("Deposit", "add_circle", Color(0xFF4CAF50)),
    asset("Asset", "inventory_2", Color(0xFF00BCD4)),
    buySell("Buy & Sell", "swap_horiz", Color(0xFFFF9800)),
    receivable("Receivable", "group", Color(0xFF2196F3)),
    wallet("Wallet", "credit_card", Color(0xFF3F51B5)),
    transfer("Transfer", "swap_horiz", Color(0xFF26A69A)),
    savings("Savings", "savings", Color(0xFF009688)),
    payment("Payment", "check_circle", Color(0xFF4CAF50));

    companion object {
        fun fromString(value: String): ActivityLogType =
            entries.firstOrNull { it.name == value } ?: expense
    }
}

// Activity Log Action
enum class ActivityLogAction(val label: String) {
    add("Add"),
    edit("Edit"),
    delete("Delete");

    companion object {
        fun fromString(value: String): ActivityLogAction =
            entries.firstOrNull { it.name == value } ?: add
    }
}

// Watchlist Item Type
enum class WatchlistItemType(
    val label: String,
    val icon: String,
    val color: Color
) {
    stock("Stock", "bar_chart", Color(0xFF9C27B0)),
    crypto("Crypto", "currency_bitcoin", Color(0xFFFF9800)),
    etf("ETF", "trending_up", Color(0xFF2196F3));

    companion object {
        fun fromString(value: String): WatchlistItemType =
            entries.firstOrNull { it.name == value } ?: stock
    }
}

// Appearance Mode
enum class AppearanceMode(val label: String, val icon: String) {
    system("System", "brightness_auto"),
    light("Light", "light_mode"),
    dark("Dark", "dark_mode");
}
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "feat: add all enum types matching iOS data model"
```

### Task 3: Create All Data Models

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/model/Wallet.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/model/Expense.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/model/Deposit.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/model/Withdrawal.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/model/Investment.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/model/InvestmentExit.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/model/BuySellTransaction.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/model/Asset.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/model/Receivable.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/model/ActivityLog.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/model/ProfitAllocation.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/model/SavingsBreakdown.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/model/WatchlistItem.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/model/WalletTransaction.kt`

- [ ] **Step 1: Create Wallet.kt**

```kotlin
package com.darskie.budgybydarskie.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.ServerTimestamp

data class Wallet(
    @DocumentId val id: String = "",
    val name: String = "",
    val type: String = WalletType.bank.name,
    val bankName: String = "",
    val balance: Double = 0.0,
    val notes: String = "",
    val year: Int = 0,
    val order: Double = 0.0,
    @ServerTimestamp val createdAt: Timestamp? = null,
    @ServerTimestamp val updatedAt: Timestamp? = null,
) {
    val walletType: WalletType get() = WalletType.fromString(type)
}
```

- [ ] **Step 2: Create Expense.kt**

```kotlin
package com.darskie.budgybydarskie.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.PropertyName
import com.google.firebase.firestore.ServerTimestamp

data class Expense(
    @DocumentId val id: String = "",
    @get:PropertyName("description") @set:PropertyName("description")
    var expenseDescription: String = "",
    val amount: Double = 0.0,
    val date: Timestamp? = null,
    val category: String = ExpenseCategory.other.name,
    val sourceId: String = "",
    val sourceName: String = "",
    val notes: String = "",
    val year: Int = 0,
    @ServerTimestamp val createdAt: Timestamp? = null,
    @ServerTimestamp val updatedAt: Timestamp? = null,
) {
    val expenseCategory: ExpenseCategory get() = ExpenseCategory.fromString(category)
    val dateAsDate: java.util.Date get() = date?.toDate() ?: java.util.Date()
}
```

- [ ] **Step 3: Create Deposit.kt**

```kotlin
package com.darskie.budgybydarskie.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.ServerTimestamp

data class Deposit(
    @DocumentId val id: String = "",
    val amount: Double = 0.0,
    val source: String = DepositSource.other.name,
    val sourceLabel: String = "",
    val walletId: String = "",
    val walletName: String = "",
    val date: Timestamp? = null,
    val notes: String = "",
    val year: Int = 0,
    @ServerTimestamp val createdAt: Timestamp? = null,
    @ServerTimestamp val updatedAt: Timestamp? = null,
) {
    val depositSource: DepositSource get() = DepositSource.fromString(source)
    val dateAsDate: java.util.Date get() = date?.toDate() ?: java.util.Date()
}
```

- [ ] **Step 4: Create Withdrawal.kt**

```kotlin
package com.darskie.budgybydarskie.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.ServerTimestamp

data class Withdrawal(
    @DocumentId val id: String = "",
    val amount: Double = 0.0,
    val fee: Double = 0.0,
    val bankWalletId: String = "",
    val bankWalletName: String = "",
    val cashWalletId: String = "",
    val cashWalletName: String = "",
    val date: Timestamp? = null,
    val year: Int = 0,
    @ServerTimestamp val createdAt: Timestamp? = null,
) {
    val dateAsDate: java.util.Date get() = date?.toDate() ?: java.util.Date()
}
```

- [ ] **Step 5: Create Investment.kt**

```kotlin
package com.darskie.budgybydarskie.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.ServerTimestamp

data class Investment(
    @DocumentId val id: String = "",
    val date: Timestamp? = null,
    val investmentType: String = InvestmentType.stock.name,
    val source: String = InvestmentSource.salary.name,
    val sourceId: String = "",
    val sourceName: String = "",
    val stock: String = "",
    val amountPhp: Double = 0.0,
    val amountUsd: Double = 0.0,
    val buyPrice: Double = 0.0,
    val quantity: Double = 0.0,
    val remarks: String = "",
    val exited: Boolean? = null,
    val year: Int = 0,
    @ServerTimestamp val createdAt: Timestamp? = null,
    @ServerTimestamp val updatedAt: Timestamp? = null,
) {
    val type: InvestmentType get() = InvestmentType.fromString(investmentType)
    val investmentSource: InvestmentSource get() = InvestmentSource.fromString(source)
    val dateAsDate: java.util.Date get() = date?.toDate() ?: java.util.Date()
    val isExited: Boolean get() = exited == true
}

data class PortfolioSummary(
    val totalInvestedPhp: Double = 0.0,
    val totalInvestedUsd: Double = 0.0,
    val totalCostBasis: Double = 0.0,
    val averageBuyPrice: Double = 0.0,
    val totalQuantity: Double = 0.0,
)

data class StockQuote(
    val price: Double = 0.0,
    val change: Double = 0.0,
    val changePercent: Double = 0.0,
)
```

- [ ] **Step 6: Create InvestmentExit.kt**

```kotlin
package com.darskie.budgybydarskie.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.ServerTimestamp

data class InvestmentExit(
    @DocumentId val id: String = "",
    val investmentId: String = "",
    val stock: String = "",
    val investmentType: String = InvestmentType.stock.name,
    val amountInvested: Double = 0.0,
    val amountOut: Double = 0.0,
    val profit: Double = 0.0,
    val destinations: List<Map<String, Any>> = emptyList(),
    val date: Timestamp? = null,
    val notes: String = "",
    val year: Int = 0,
    @ServerTimestamp val createdAt: Timestamp? = null,
) {
    val type: InvestmentType get() = InvestmentType.fromString(investmentType)
    val dateAsDate: java.util.Date get() = date?.toDate() ?: java.util.Date()

    val fundingDestinations: List<FundingSource>
        get() = destinations.map { map ->
            FundingSource(
                sourceId = map["sourceId"] as? String ?: "",
                sourceName = map["sourceName"] as? String ?: "",
                amount = (map["amount"] as? Number)?.toDouble() ?: 0.0,
            )
        }
}
```

- [ ] **Step 7: Create BuySellTransaction.kt**

```kotlin
package com.darskie.budgybydarskie.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.ServerTimestamp

data class FundingSource(
    val sourceId: String = "",
    val sourceName: String = "",
    val amount: Double = 0.0,
)

data class BuySellTransaction(
    @DocumentId val id: String = "",
    val itemName: String = "",
    val itemType: String = ItemType.other.name,
    val buyPrice: Double = 0.0,
    val sellPrice: Double? = null,
    val profit: Double? = null,
    val fundingSources: List<Map<String, Any>> = emptyList(),
    val buyerName: String? = null,
    val dateBought: Timestamp? = null,
    val dateSold: Timestamp? = null,
    val soldDestinations: List<Map<String, Any>>? = null,
    val status: String = BuySellStatus.available.name,
    val notes: String = "",
    val year: Int = 0,
    val order: Double = 0.0,
    @ServerTimestamp val createdAt: Timestamp? = null,
    @ServerTimestamp val updatedAt: Timestamp? = null,
) {
    val type: ItemType get() = ItemType.fromString(itemType)
    val buySellStatus: BuySellStatus get() = BuySellStatus.fromString(status)

    val fundingSourceList: List<FundingSource>
        get() = fundingSources.map { map ->
            FundingSource(
                sourceId = map["sourceId"] as? String ?: "",
                sourceName = map["sourceName"] as? String ?: "",
                amount = (map["amount"] as? Number)?.toDouble() ?: 0.0,
            )
        }

    val soldDestinationList: List<FundingSource>
        get() = (soldDestinations ?: emptyList()).map { map ->
            FundingSource(
                sourceId = map["sourceId"] as? String ?: "",
                sourceName = map["sourceName"] as? String ?: "",
                amount = (map["amount"] as? Number)?.toDouble() ?: 0.0,
            )
        }
}
```

- [ ] **Step 8: Create Asset.kt**

```kotlin
package com.darskie.budgybydarskie.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.ServerTimestamp

data class Asset(
    @DocumentId val id: String = "",
    val name: String = "",
    val category: String = AssetCategory.other.name,
    val amount: Double = 0.0,
    val sourceId: String = "",
    val sourceName: String = "",
    val notes: String = "",
    val year: Int = 0,
    val order: Double = 0.0,
    @ServerTimestamp val createdAt: Timestamp? = null,
    @ServerTimestamp val updatedAt: Timestamp? = null,
) {
    val assetCategory: AssetCategory get() = AssetCategory.fromString(category)
}
```

- [ ] **Step 9: Create Receivable.kt**

```kotlin
package com.darskie.budgybydarskie.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.PropertyName
import com.google.firebase.firestore.ServerTimestamp

data class Receivable(
    @DocumentId val id: String = "",
    val name: String = "",
    @get:PropertyName("description") @set:PropertyName("description")
    var receivableDescription: String = "",
    val amount: Double = 0.0,
    val sourceId: String = "",
    val sourceName: String = "",
    val isReimbursement: Boolean = false,
    val notes: String = "",
    val year: Int = 0,
    val order: Double = 0.0,
    val totalPaid: Double? = null,
    @ServerTimestamp val createdAt: Timestamp? = null,
    @ServerTimestamp val updatedAt: Timestamp? = null,
) {
    val remaining: Double get() = amount - (totalPaid ?: 0.0)
    val isFullyPaid: Boolean get() = remaining <= 0.0
}

data class PaymentDestination(
    val walletId: String = "",
    val walletName: String = "",
    val amount: Double = 0.0,
)

data class ReceivablePayment(
    @DocumentId val id: String = "",
    val amount: Double = 0.0,
    val date: Timestamp? = null,
    val destinations: List<Map<String, Any>> = emptyList(),
    val notes: String = "",
    @ServerTimestamp val createdAt: Timestamp? = null,
) {
    val dateAsDate: java.util.Date get() = date?.toDate() ?: java.util.Date()

    val paymentDestinations: List<PaymentDestination>
        get() = destinations.map { map ->
            PaymentDestination(
                walletId = map["walletId"] as? String ?: "",
                walletName = map["walletName"] as? String ?: "",
                amount = (map["amount"] as? Number)?.toDouble() ?: 0.0,
            )
        }
}
```

- [ ] **Step 10: Create ActivityLog.kt**

```kotlin
package com.darskie.budgybydarskie.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.ServerTimestamp

data class ActivityLog(
    @DocumentId val id: String = "",
    val type: String = ActivityLogType.expense.name,
    val action: String = ActivityLogAction.add.name,
    val description: String = "",
    val amount: Double? = null,
    val year: Int = 0,
    @ServerTimestamp val createdAt: Timestamp? = null,
) {
    val logType: ActivityLogType get() = ActivityLogType.fromString(type)
    val logAction: ActivityLogAction get() = ActivityLogAction.fromString(action)
    val dateAsDate: java.util.Date get() = createdAt?.toDate() ?: java.util.Date()
}
```

- [ ] **Step 11: Create ProfitAllocation.kt**

```kotlin
package com.darskie.budgybydarskie.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.ServerTimestamp

data class ProfitAllocation(
    @DocumentId val id: String = "",
    val label: String = "",
    val destType: String = "",
    val amount: Double = 0.0,
    val year: Int = 0,
    @ServerTimestamp val createdAt: Timestamp? = null,
    @ServerTimestamp val updatedAt: Timestamp? = null,
)
```

- [ ] **Step 12: Create SavingsBreakdown.kt**

```kotlin
package com.darskie.budgybydarskie.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.ServerTimestamp

data class SavingsBreakdown(
    @DocumentId val id: String = "",
    val label: String = "",
    val amount: Double = 0.0,
    val year: Int = 0,
    @ServerTimestamp val updatedAt: Timestamp? = null,
)
```

- [ ] **Step 13: Create WatchlistItem.kt**

```kotlin
package com.darskie.budgybydarskie.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.ServerTimestamp

data class WatchlistItem(
    @DocumentId val id: String = "",
    val symbol: String = "",
    val name: String = "",
    val type: String = WatchlistItemType.stock.name,
    val order: Double = 0.0,
    @ServerTimestamp val createdAt: Timestamp? = null,
) {
    val itemType: WatchlistItemType get() = WatchlistItemType.fromString(type)
}

data class WatchlistQuote(
    val price: Double = 0.0,
    val change: Double = 0.0,
    val changePercent: Double = 0.0,
    val sparkline: List<Double> = emptyList(),
)
```

- [ ] **Step 14: Create WalletTransaction.kt**

```kotlin
package com.darskie.budgybydarskie.data.model

import java.util.Date

data class WalletTransaction(
    val id: String,
    val type: WalletTransactionType,
    val title: String,
    val subtitle: String,
    val amount: Double,
    val date: Date,
    val notes: String = "",
)
```

- [ ] **Step 15: Commit**

```bash
git add -A && git commit -m "feat: add all data models matching iOS Firestore schema"
```

---

## Phase 3: Utilities & Constants

### Task 4: Create Utilities

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/util/Constants.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/util/CurrencyFormatter.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/util/DateExtensions.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/util/NetworkMonitor.kt`

- [ ] **Step 1: Create Constants.kt**

```kotlin
package com.darskie.budgybydarskie.util

const val CURRENT_YEAR = 2026

val SAVINGS_LABELS = listOf(
    "Savings",
    "Milestone - Q3 - 2025",
    "Milestone - Q4 - 2025",
    "BS Profit - Cash",
    "BS Profit - S&P500",
    "Old Savings (now in VOO)",
    "Salary 2026 Savings (now in VOO)",
    "Bybit Old Savings",
)

val KNOWN_BANKS = listOf("MariBank", "GoTyme Bank", "Union Bank", "GCash", "BPI", "BDO")
```

- [ ] **Step 2: Create CurrencyFormatter.kt**

```kotlin
package com.darskie.budgybydarskie.util

import java.text.NumberFormat
import java.util.Currency
import java.util.Locale

fun formatPhp(amount: Double): String {
    val formatter = NumberFormat.getCurrencyInstance(Locale("en", "PH"))
    formatter.currency = Currency.getInstance("PHP")
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2
    return formatter.format(amount).replace("PHP", "\u20B1")
}

fun formatUsd(amount: Double): String {
    val formatter = NumberFormat.getCurrencyInstance(Locale.US)
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter.format(amount)
}

fun formatNumber(amount: Double, decimals: Int = 2): String {
    val formatter = NumberFormat.getNumberInstance()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = decimals
    return formatter.format(amount)
}
```

- [ ] **Step 3: Create DateExtensions.kt**

```kotlin
package com.darskie.budgybydarskie.util

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

fun Date.formattedMMMddyyyy(): String =
    SimpleDateFormat("MMM dd, yyyy", Locale.US).format(this)

fun Date.formattedMMddyy(): String =
    SimpleDateFormat("MM/dd/yy", Locale.US).format(this)

fun Date.formattedMMMMyyyy(): String =
    SimpleDateFormat("MMMM yyyy", Locale.US).format(this)

fun Date.formattedMedium(): String =
    SimpleDateFormat("MMM dd, yyyy", Locale.US).format(this)

fun Date.isToday(): Boolean {
    val sdf = SimpleDateFormat("yyyyMMdd", Locale.US)
    return sdf.format(this) == sdf.format(Date())
}

fun Date.isThisWeek(): Boolean {
    val cal = java.util.Calendar.getInstance()
    val currentWeek = cal.get(java.util.Calendar.WEEK_OF_YEAR)
    val currentYear = cal.get(java.util.Calendar.YEAR)
    cal.time = this
    return cal.get(java.util.Calendar.WEEK_OF_YEAR) == currentWeek &&
        cal.get(java.util.Calendar.YEAR) == currentYear
}

fun Date.isThisMonth(): Boolean {
    val cal = java.util.Calendar.getInstance()
    val currentMonth = cal.get(java.util.Calendar.MONTH)
    val currentYear = cal.get(java.util.Calendar.YEAR)
    cal.time = this
    return cal.get(java.util.Calendar.MONTH) == currentMonth &&
        cal.get(java.util.Calendar.YEAR) == currentYear
}
```

- [ ] **Step 4: Create NetworkMonitor.kt**

```kotlin
package com.darskie.budgybydarskie.util

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NetworkMonitor @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    val isConnected: Flow<Boolean> = callbackFlow {
        val connectivityManager =
            context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) { trySend(true) }
            override fun onLost(network: Network) { trySend(false) }
        }

        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()

        connectivityManager.registerNetworkCallback(request, callback)

        // Emit initial state
        val activeNetwork = connectivityManager.activeNetwork
        val capabilities = connectivityManager.getNetworkCapabilities(activeNetwork)
        trySend(capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true)

        awaitClose { connectivityManager.unregisterNetworkCallback(callback) }
    }
}
```

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: add utility classes — constants, currency formatting, date extensions, network monitor"
```

---

## Phase 4: Dependency Injection

### Task 5: Create Hilt Modules

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/BudgyApp.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/di/AppModule.kt`

- [ ] **Step 1: Create BudgyApp.kt (Hilt Application)**

```kotlin
package com.darskie.budgybydarskie

import android.app.Application
import com.google.firebase.FirebaseApp
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class BudgyApp : Application() {
    override fun onCreate() {
        super.onCreate()
        FirebaseApp.initializeApp(this)
    }
}
```

- [ ] **Step 2: Create AppModule.kt**

```kotlin
package com.darskie.budgybydarskie.di

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStore
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideFirebaseAuth(): FirebaseAuth = FirebaseAuth.getInstance()

    @Provides
    @Singleton
    fun provideFirestore(): FirebaseFirestore = FirebaseFirestore.getInstance()

    @Provides
    @Singleton
    fun provideDataStore(@ApplicationContext context: Context): DataStore<Preferences> =
        context.dataStore
}
```

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: add Hilt DI setup with Firebase and DataStore providers"
```

---

## Phase 5: Repository Layer (Firestore Services)

### Task 6: Create ActivityLogRepository

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/repository/ActivityLogRepository.kt`

- [ ] **Step 1: Implement ActivityLogRepository**

```kotlin
package com.darskie.budgybydarskie.data.repository

import com.darskie.budgybydarskie.data.model.ActivityLog
import com.darskie.budgybydarskie.data.model.ActivityLogAction
import com.darskie.budgybydarskie.data.model.ActivityLogType
import com.darskie.budgybydarskie.util.CURRENT_YEAR
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ActivityLogRepository @Inject constructor(
    private val db: FirebaseFirestore,
) {
    private fun col(uid: String) = db.collection("users").document(uid).collection("activityLog")

    fun log(uid: String, type: ActivityLogType, action: ActivityLogAction, description: String, amount: Double? = null) {
        val data = mutableMapOf<String, Any>(
            "type" to type.name,
            "action" to action.name,
            "description" to description,
            "year" to CURRENT_YEAR,
            "createdAt" to FieldValue.serverTimestamp(),
        )
        if (amount != null) data["amount"] = amount
        col(uid).add(data)
    }

    fun subscribe(uid: String, limit: Int = 200, onChange: (List<ActivityLog>) -> Unit): ListenerRegistration {
        return col(uid)
            .orderBy("createdAt", com.google.firebase.firestore.Query.Direction.DESCENDING)
            .limit(limit.toLong())
            .addSnapshotListener { snapshot, _ ->
                val logs = snapshot?.documents?.mapNotNull { it.toObject(ActivityLog::class.java) } ?: emptyList()
                onChange(logs)
            }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "feat: add ActivityLogRepository"
```

### Task 7: Create WalletRepository

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/repository/WalletRepository.kt`

- [ ] **Step 1: Implement WalletRepository**

```kotlin
package com.darskie.budgybydarskie.data.repository

import com.darskie.budgybydarskie.data.model.ActivityLogAction
import com.darskie.budgybydarskie.data.model.ActivityLogType
import com.darskie.budgybydarskie.data.model.Wallet
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WalletRepository @Inject constructor(
    private val db: FirebaseFirestore,
    private val activityLog: ActivityLogRepository,
) {
    private fun col(uid: String) = db.collection("users").document(uid).collection("wallets")

    fun subscribe(uid: String, year: Int, onChange: (List<Wallet>) -> Unit): ListenerRegistration {
        return col(uid)
            .whereEqualTo("year", year)
            .addSnapshotListener { snapshot, _ ->
                val wallets = snapshot?.documents
                    ?.mapNotNull { it.toObject(Wallet::class.java) }
                    ?.sortedWith(compareBy({ it.type }, { it.order }))
                    ?: emptyList()
                onChange(wallets)
            }
    }

    suspend fun add(uid: String, wallet: Wallet): String {
        val docId = col(uid).document().id
        val data = mapOf(
            "name" to wallet.name,
            "type" to wallet.type,
            "bankName" to wallet.bankName,
            "balance" to wallet.balance,
            "notes" to wallet.notes,
            "year" to wallet.year,
            "order" to System.currentTimeMillis().toDouble(),
            "createdAt" to FieldValue.serverTimestamp(),
            "updatedAt" to FieldValue.serverTimestamp(),
        )
        col(uid).document(docId).set(data).await()
        activityLog.log(uid, ActivityLogType.wallet, ActivityLogAction.add, "Added wallet: ${wallet.name}", wallet.balance)
        return docId
    }

    suspend fun update(uid: String, walletId: String, data: Map<String, Any>) {
        val mutableData = data.toMutableMap()
        mutableData["updatedAt"] = FieldValue.serverTimestamp()
        col(uid).document(walletId).update(mutableData).await()
        activityLog.log(uid, ActivityLogType.wallet, ActivityLogAction.edit, "Updated wallet")
    }

    suspend fun delete(uid: String, walletId: String) {
        col(uid).document(walletId).delete().await()
        activityLog.log(uid, ActivityLogType.wallet, ActivityLogAction.delete, "Deleted wallet")
    }

    suspend fun transfer(uid: String, sourceWalletId: String, destWalletId: String, amount: Double, fee: Double, sourceName: String) {
        val batch = db.batch()
        val sourceRef = col(uid).document(sourceWalletId)
        val destRef = col(uid).document(destWalletId)

        batch.update(sourceRef, mapOf(
            "balance" to FieldValue.increment(-(amount + fee)),
            "updatedAt" to FieldValue.serverTimestamp(),
        ))
        batch.update(destRef, mapOf(
            "balance" to FieldValue.increment(amount),
            "updatedAt" to FieldValue.serverTimestamp(),
        ))

        // Record withdrawal
        val withdrawalRef = db.collection("users").document(uid).collection("withdrawals").document()
        batch.set(withdrawalRef, mapOf(
            "amount" to amount,
            "fee" to fee,
            "bankWalletId" to sourceWalletId,
            "bankWalletName" to sourceName,
            "cashWalletId" to destWalletId,
            "cashWalletName" to "", // filled by caller
            "date" to Timestamp.now(),
            "year" to com.darskie.budgybydarskie.util.CURRENT_YEAR,
            "createdAt" to FieldValue.serverTimestamp(),
        ))

        // Record fee as expense if > 0
        if (fee > 0) {
            val expenseRef = db.collection("users").document(uid).collection("expenses").document()
            batch.set(expenseRef, mapOf(
                "description" to "Transfer Fee",
                "amount" to fee,
                "date" to Timestamp.now(),
                "category" to "other",
                "sourceId" to sourceWalletId,
                "sourceName" to sourceName,
                "notes" to "Auto-generated from transfer",
                "year" to com.darskie.budgybydarskie.util.CURRENT_YEAR,
                "createdAt" to FieldValue.serverTimestamp(),
                "updatedAt" to FieldValue.serverTimestamp(),
            ))
        }

        batch.commit().await()
        activityLog.log(uid, ActivityLogType.transfer, ActivityLogAction.add, "Transferred ${amount}", amount)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "feat: add WalletRepository with CRUD and transfer logic"
```

### Task 8: Create ExpenseRepository

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/repository/ExpenseRepository.kt`

- [ ] **Step 1: Implement ExpenseRepository**

```kotlin
package com.darskie.budgybydarskie.data.repository

import com.darskie.budgybydarskie.data.model.ActivityLogAction
import com.darskie.budgybydarskie.data.model.ActivityLogType
import com.darskie.budgybydarskie.data.model.Expense
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ExpenseRepository @Inject constructor(
    private val db: FirebaseFirestore,
    private val activityLog: ActivityLogRepository,
) {
    private fun col(uid: String) = db.collection("users").document(uid).collection("expenses")

    fun subscribe(uid: String, year: Int, onChange: (List<Expense>) -> Unit): ListenerRegistration {
        return col(uid)
            .whereEqualTo("year", year)
            .addSnapshotListener { snapshot, _ ->
                val expenses = snapshot?.documents
                    ?.mapNotNull { it.toObject(Expense::class.java) }
                    ?.sortedByDescending { it.date }
                    ?: emptyList()
                onChange(expenses)
            }
    }

    fun add(uid: String, expense: Expense): String {
        val walletRef = db.collection("users").document(uid).collection("wallets").document(expense.sourceId)
        val docId = col(uid).document().id
        val expenseRef = col(uid).document(docId)

        val batch = db.batch()
        batch.update(walletRef, mapOf(
            "balance" to FieldValue.increment(-expense.amount),
            "updatedAt" to FieldValue.serverTimestamp(),
        ))
        batch.set(expenseRef, mapOf(
            "description" to expense.expenseDescription,
            "amount" to expense.amount,
            "date" to (expense.date ?: Timestamp.now()),
            "category" to expense.category,
            "sourceId" to expense.sourceId,
            "sourceName" to expense.sourceName,
            "notes" to expense.notes,
            "year" to expense.year,
            "createdAt" to FieldValue.serverTimestamp(),
            "updatedAt" to FieldValue.serverTimestamp(),
        ))
        batch.commit()
        activityLog.log(uid, ActivityLogType.expense, ActivityLogAction.add, "Added expense: ${expense.expenseDescription}", expense.amount)
        return docId
    }

    fun update(uid: String, expenseId: String, oldAmount: Double, oldSourceId: String, expense: Expense) {
        val batch = db.batch()
        val oldWalletRef = db.collection("users").document(uid).collection("wallets").document(oldSourceId)
        val newWalletRef = db.collection("users").document(uid).collection("wallets").document(expense.sourceId)
        val expenseRef = col(uid).document(expenseId)

        if (oldSourceId == expense.sourceId) {
            batch.update(oldWalletRef, mapOf(
                "balance" to FieldValue.increment(oldAmount - expense.amount),
                "updatedAt" to FieldValue.serverTimestamp(),
            ))
        } else {
            batch.update(oldWalletRef, mapOf(
                "balance" to FieldValue.increment(oldAmount),
                "updatedAt" to FieldValue.serverTimestamp(),
            ))
            batch.update(newWalletRef, mapOf(
                "balance" to FieldValue.increment(-expense.amount),
                "updatedAt" to FieldValue.serverTimestamp(),
            ))
        }

        batch.update(expenseRef, mapOf(
            "description" to expense.expenseDescription,
            "amount" to expense.amount,
            "date" to (expense.date ?: Timestamp.now()),
            "category" to expense.category,
            "sourceId" to expense.sourceId,
            "sourceName" to expense.sourceName,
            "notes" to expense.notes,
            "updatedAt" to FieldValue.serverTimestamp(),
        ))
        batch.commit()
        activityLog.log(uid, ActivityLogType.expense, ActivityLogAction.edit, "Updated expense: ${expense.expenseDescription}", expense.amount)
    }

    fun delete(uid: String, expenseId: String, sourceId: String, amount: Double) {
        val batch = db.batch()
        val walletRef = db.collection("users").document(uid).collection("wallets").document(sourceId)
        val expenseRef = col(uid).document(expenseId)

        batch.update(walletRef, mapOf(
            "balance" to FieldValue.increment(amount),
            "updatedAt" to FieldValue.serverTimestamp(),
        ))
        batch.delete(expenseRef)
        batch.commit()
        activityLog.log(uid, ActivityLogType.expense, ActivityLogAction.delete, "Deleted expense", amount)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "feat: add ExpenseRepository with batch wallet balance updates"
```

### Task 9: Create DepositRepository

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/repository/DepositRepository.kt`

- [ ] **Step 1: Implement DepositRepository**

```kotlin
package com.darskie.budgybydarskie.data.repository

import com.darskie.budgybydarskie.data.model.ActivityLogAction
import com.darskie.budgybydarskie.data.model.ActivityLogType
import com.darskie.budgybydarskie.data.model.Deposit
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DepositRepository @Inject constructor(
    private val db: FirebaseFirestore,
    private val activityLog: ActivityLogRepository,
) {
    private fun col(uid: String) = db.collection("users").document(uid).collection("deposits")

    fun subscribe(uid: String, year: Int, onChange: (List<Deposit>) -> Unit): ListenerRegistration {
        return col(uid)
            .whereEqualTo("year", year)
            .addSnapshotListener { snapshot, _ ->
                val deposits = snapshot?.documents
                    ?.mapNotNull { it.toObject(Deposit::class.java) }
                    ?.sortedByDescending { it.date }
                    ?: emptyList()
                onChange(deposits)
            }
    }

    fun add(uid: String, deposit: Deposit): String {
        val walletRef = db.collection("users").document(uid).collection("wallets").document(deposit.walletId)
        val docId = col(uid).document().id
        val depositRef = col(uid).document(docId)

        val batch = db.batch()
        batch.update(walletRef, mapOf(
            "balance" to FieldValue.increment(deposit.amount),
            "updatedAt" to FieldValue.serverTimestamp(),
        ))
        batch.set(depositRef, mapOf(
            "amount" to deposit.amount,
            "source" to deposit.source,
            "sourceLabel" to deposit.sourceLabel,
            "walletId" to deposit.walletId,
            "walletName" to deposit.walletName,
            "date" to (deposit.date ?: Timestamp.now()),
            "notes" to deposit.notes,
            "year" to deposit.year,
            "createdAt" to FieldValue.serverTimestamp(),
            "updatedAt" to FieldValue.serverTimestamp(),
        ))
        batch.commit()
        activityLog.log(uid, ActivityLogType.deposit, ActivityLogAction.add, "Deposited to ${deposit.walletName}", deposit.amount)
        return docId
    }

    fun delete(uid: String, depositId: String, walletId: String, amount: Double) {
        val walletRef = db.collection("users").document(uid).collection("wallets").document(walletId)
        val depositRef = col(uid).document(depositId)

        val batch = db.batch()
        batch.update(walletRef, mapOf(
            "balance" to FieldValue.increment(-amount),
            "updatedAt" to FieldValue.serverTimestamp(),
        ))
        batch.delete(depositRef)
        batch.commit()
        activityLog.log(uid, ActivityLogType.deposit, ActivityLogAction.delete, "Deleted deposit", amount)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "feat: add DepositRepository"
```

### Task 10: Create InvestmentRepository

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/repository/InvestmentRepository.kt`

- [ ] **Step 1: Implement InvestmentRepository**

```kotlin
package com.darskie.budgybydarskie.data.repository

import com.darskie.budgybydarskie.data.model.ActivityLogAction
import com.darskie.budgybydarskie.data.model.ActivityLogType
import com.darskie.budgybydarskie.data.model.FundingSource
import com.darskie.budgybydarskie.data.model.Investment
import com.darskie.budgybydarskie.data.model.InvestmentExit
import com.darskie.budgybydarskie.util.CURRENT_YEAR
import com.darskie.budgybydarskie.util.formatPhp
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.Query
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class InvestmentRepository @Inject constructor(
    private val db: FirebaseFirestore,
    private val activityLog: ActivityLogRepository,
) {
    private fun col(uid: String) = db.collection("users").document(uid).collection("investments")

    fun subscribe(uid: String, year: Int?, onChange: (List<Investment>) -> Unit): ListenerRegistration {
        var query: Query = col(uid)
        if (year != null) query = query.whereEqualTo("year", year)

        return query.addSnapshotListener { snapshot, _ ->
            val investments = snapshot?.documents
                ?.mapNotNull { it.toObject(Investment::class.java) }
                ?.sortedByDescending { it.date }
                ?: emptyList()
            onChange(investments)
        }
    }

    fun add(uid: String, investment: Investment): String {
        val walletRef = db.collection("users").document(uid).collection("wallets").document(investment.sourceId)
        val docId = col(uid).document().id
        val ref = col(uid).document(docId)

        val batch = db.batch()
        batch.update(walletRef, mapOf(
            "balance" to FieldValue.increment(-investment.amountPhp),
            "updatedAt" to FieldValue.serverTimestamp(),
        ))
        batch.set(ref, mapOf(
            "date" to (investment.date ?: Timestamp.now()),
            "investmentType" to investment.investmentType,
            "source" to investment.source,
            "sourceId" to investment.sourceId,
            "sourceName" to investment.sourceName,
            "stock" to investment.stock,
            "amountPhp" to investment.amountPhp,
            "amountUsd" to investment.amountUsd,
            "buyPrice" to investment.buyPrice,
            "quantity" to investment.quantity,
            "remarks" to investment.remarks,
            "year" to investment.year,
            "createdAt" to FieldValue.serverTimestamp(),
            "updatedAt" to FieldValue.serverTimestamp(),
        ))
        batch.commit()
        activityLog.log(uid, ActivityLogType.investment, ActivityLogAction.add, "Added investment: ${investment.stock}", investment.amountPhp)
        return docId
    }

    fun update(uid: String, investmentId: String, oldAmountPhp: Double, oldSourceId: String, investment: Investment) {
        val batch = db.batch()
        val oldWalletRef = db.collection("users").document(uid).collection("wallets").document(oldSourceId)
        val newWalletRef = db.collection("users").document(uid).collection("wallets").document(investment.sourceId)
        val investmentRef = col(uid).document(investmentId)

        if (oldSourceId == investment.sourceId) {
            batch.update(oldWalletRef, mapOf(
                "balance" to FieldValue.increment(oldAmountPhp - investment.amountPhp),
                "updatedAt" to FieldValue.serverTimestamp(),
            ))
        } else {
            batch.update(oldWalletRef, mapOf("balance" to FieldValue.increment(oldAmountPhp), "updatedAt" to FieldValue.serverTimestamp()))
            batch.update(newWalletRef, mapOf("balance" to FieldValue.increment(-investment.amountPhp), "updatedAt" to FieldValue.serverTimestamp()))
        }

        batch.update(investmentRef, mapOf(
            "date" to (investment.date ?: Timestamp.now()),
            "investmentType" to investment.investmentType,
            "source" to investment.source,
            "sourceId" to investment.sourceId,
            "sourceName" to investment.sourceName,
            "stock" to investment.stock,
            "amountPhp" to investment.amountPhp,
            "amountUsd" to investment.amountUsd,
            "buyPrice" to investment.buyPrice,
            "quantity" to investment.quantity,
            "remarks" to investment.remarks,
            "updatedAt" to FieldValue.serverTimestamp(),
        ))
        batch.commit()
        activityLog.log(uid, ActivityLogType.investment, ActivityLogAction.edit, "Updated investment: ${investment.stock}", investment.amountPhp)
    }

    fun tpsl(uid: String, exit: InvestmentExit, destinations: List<FundingSource>) {
        val batch = db.batch()

        for (dest in destinations) {
            val walletRef = db.collection("users").document(uid).collection("wallets").document(dest.sourceId)
            batch.update(walletRef, mapOf(
                "balance" to FieldValue.increment(dest.amount),
                "updatedAt" to FieldValue.serverTimestamp(),
            ))
        }

        val investmentRef = col(uid).document(exit.investmentId)
        batch.update(investmentRef, mapOf("exited" to true, "updatedAt" to FieldValue.serverTimestamp()))

        val exitRef = db.collection("users").document(uid).collection("investmentExits").document()
        val destData = destinations.map { mapOf("sourceId" to it.sourceId, "sourceName" to it.sourceName, "amount" to it.amount) }
        batch.set(exitRef, mapOf(
            "investmentId" to exit.investmentId,
            "stock" to exit.stock,
            "investmentType" to exit.investmentType,
            "amountInvested" to exit.amountInvested,
            "amountOut" to exit.amountOut,
            "profit" to exit.profit,
            "destinations" to destData,
            "date" to (exit.date ?: Timestamp.now()),
            "notes" to exit.notes,
            "year" to exit.year,
            "createdAt" to FieldValue.serverTimestamp(),
        ))
        batch.commit()

        val action = if (exit.profit >= 0) "TP" else "SL"
        activityLog.log(uid, ActivityLogType.investment, ActivityLogAction.edit, "$action: ${exit.stock} -> ${formatPhp(exit.amountOut)}", exit.amountOut)
    }

    fun delete(uid: String, investmentId: String, sourceId: String, amountPhp: Double) {
        if (sourceId.isEmpty()) {
            col(uid).document(investmentId).delete()
            return
        }
        val batch = db.batch()
        val walletRef = db.collection("users").document(uid).collection("wallets").document(sourceId)
        batch.update(walletRef, mapOf("balance" to FieldValue.increment(amountPhp), "updatedAt" to FieldValue.serverTimestamp()))
        batch.delete(col(uid).document(investmentId))
        batch.commit()
        activityLog.log(uid, ActivityLogType.investment, ActivityLogAction.delete, "Deleted investment", amountPhp)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "feat: add InvestmentRepository with TP/SL logic"
```

### Task 11: Create BuySellRepository

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/repository/BuySellRepository.kt`

- [ ] **Step 1: Implement BuySellRepository**

```kotlin
package com.darskie.budgybydarskie.data.repository

import com.darskie.budgybydarskie.data.model.ActivityLogAction
import com.darskie.budgybydarskie.data.model.ActivityLogType
import com.darskie.budgybydarskie.data.model.BuySellTransaction
import com.darskie.budgybydarskie.data.model.FundingSource
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class BuySellRepository @Inject constructor(
    private val db: FirebaseFirestore,
    private val activityLog: ActivityLogRepository,
) {
    private fun col(uid: String) = db.collection("users").document(uid).collection("buySellTransactions")

    fun subscribe(uid: String, year: Int, onChange: (List<BuySellTransaction>) -> Unit): ListenerRegistration {
        return col(uid)
            .whereEqualTo("year", year)
            .addSnapshotListener { snapshot, _ ->
                val txs = snapshot?.documents
                    ?.mapNotNull { it.toObject(BuySellTransaction::class.java) }
                    ?.sortedByDescending { it.order }
                    ?: emptyList()
                onChange(txs)
            }
    }

    fun add(uid: String, tx: BuySellTransaction, fundingSources: List<FundingSource>): String {
        val buyPrice = fundingSources.sumOf { it.amount }
        val docId = col(uid).document().id
        val ref = col(uid).document(docId)
        val batch = db.batch()

        for (src in fundingSources) {
            val walletRef = db.collection("users").document(uid).collection("wallets").document(src.sourceId)
            batch.update(walletRef, mapOf("balance" to FieldValue.increment(-src.amount), "updatedAt" to FieldValue.serverTimestamp()))
        }

        val fundingData = fundingSources.map { mapOf("sourceId" to it.sourceId, "sourceName" to it.sourceName, "amount" to it.amount) }
        val data = mutableMapOf<String, Any>(
            "itemName" to tx.itemName,
            "itemType" to tx.itemType,
            "buyPrice" to buyPrice,
            "fundingSources" to fundingData,
            "status" to tx.status,
            "notes" to tx.notes,
            "year" to tx.year,
            "order" to System.currentTimeMillis().toDouble(),
            "createdAt" to FieldValue.serverTimestamp(),
            "updatedAt" to FieldValue.serverTimestamp(),
        )
        if (tx.dateBought != null) data["dateBought"] = tx.dateBought!!

        batch.set(ref, data)
        batch.commit()
        activityLog.log(uid, ActivityLogType.buySell, ActivityLogAction.add, "Added B&S: ${tx.itemName}", buyPrice)
        return docId
    }

    fun markAsSold(uid: String, txId: String, buyPrice: Double, sellPrice: Double, buyerName: String, dateSold: Timestamp, soldDestinations: List<FundingSource>) {
        val txRef = col(uid).document(txId)
        val profit = sellPrice - buyPrice
        val batch = db.batch()

        for (dest in soldDestinations) {
            val walletRef = db.collection("users").document(uid).collection("wallets").document(dest.sourceId)
            batch.update(walletRef, mapOf("balance" to FieldValue.increment(dest.amount), "updatedAt" to FieldValue.serverTimestamp()))
        }

        val destData = soldDestinations.map { mapOf("sourceId" to it.sourceId, "sourceName" to it.sourceName, "amount" to it.amount) }
        val data = mutableMapOf<String, Any>(
            "sellPrice" to sellPrice,
            "profit" to profit,
            "dateSold" to dateSold,
            "soldDestinations" to destData,
            "status" to "sold",
            "updatedAt" to FieldValue.serverTimestamp(),
        )
        if (buyerName.isNotEmpty()) data["buyerName"] = buyerName

        batch.update(txRef, data)
        batch.commit()
        activityLog.log(uid, ActivityLogType.buySell, ActivityLogAction.edit, "Sold item for $sellPrice", sellPrice)
    }

    fun delete(uid: String, txId: String, fundingSources: List<FundingSource>) {
        val batch = db.batch()
        for (src in fundingSources) {
            if (src.sourceId.isNotEmpty()) {
                val walletRef = db.collection("users").document(uid).collection("wallets").document(src.sourceId)
                batch.update(walletRef, mapOf("balance" to FieldValue.increment(src.amount), "updatedAt" to FieldValue.serverTimestamp()))
            }
        }
        batch.delete(col(uid).document(txId))
        batch.commit()
        activityLog.log(uid, ActivityLogType.buySell, ActivityLogAction.delete, "Deleted B&S transaction", fundingSources.sumOf { it.amount })
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "feat: add BuySellRepository with multi-source funding and sold flow"
```

### Task 12: Create AssetRepository

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/repository/AssetRepository.kt`

- [ ] **Step 1: Implement AssetRepository**

```kotlin
package com.darskie.budgybydarskie.data.repository

import com.darskie.budgybydarskie.data.model.ActivityLogAction
import com.darskie.budgybydarskie.data.model.ActivityLogType
import com.darskie.budgybydarskie.data.model.Asset
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AssetRepository @Inject constructor(
    private val db: FirebaseFirestore,
    private val activityLog: ActivityLogRepository,
) {
    private fun col(uid: String) = db.collection("users").document(uid).collection("assets")

    fun subscribe(uid: String, year: Int, onChange: (List<Asset>) -> Unit): ListenerRegistration {
        return col(uid)
            .whereEqualTo("year", year)
            .addSnapshotListener { snapshot, _ ->
                val assets = snapshot?.documents
                    ?.mapNotNull { it.toObject(Asset::class.java) }
                    ?.sortedWith(compareBy({ it.category }, { it.order }))
                    ?: emptyList()
                onChange(assets)
            }
    }

    fun add(uid: String, asset: Asset): String {
        val docId = col(uid).document().id
        val assetRef = col(uid).document(docId)
        val data = mapOf(
            "name" to asset.name, "category" to asset.category, "amount" to asset.amount,
            "sourceId" to asset.sourceId, "sourceName" to asset.sourceName, "notes" to asset.notes,
            "year" to asset.year, "order" to System.currentTimeMillis().toDouble(),
            "createdAt" to FieldValue.serverTimestamp(), "updatedAt" to FieldValue.serverTimestamp(),
        )
        if (asset.sourceId.isEmpty()) {
            assetRef.set(data)
        } else {
            val batch = db.batch()
            val walletRef = db.collection("users").document(uid).collection("wallets").document(asset.sourceId)
            batch.update(walletRef, mapOf("balance" to FieldValue.increment(-asset.amount), "updatedAt" to FieldValue.serverTimestamp()))
            batch.set(assetRef, data)
            batch.commit()
        }
        activityLog.log(uid, ActivityLogType.asset, ActivityLogAction.add, "Added asset: ${asset.name}", asset.amount)
        return docId
    }

    fun update(uid: String, assetId: String, oldAmount: Double, oldSourceId: String, asset: Asset) {
        val batch = db.batch()
        val assetRef = col(uid).document(assetId)
        val oldWalletRef = db.collection("users").document(uid).collection("wallets").document(oldSourceId)
        val newWalletRef = db.collection("users").document(uid).collection("wallets").document(asset.sourceId)

        if (oldSourceId == asset.sourceId) {
            batch.update(oldWalletRef, mapOf("balance" to FieldValue.increment(oldAmount - asset.amount), "updatedAt" to FieldValue.serverTimestamp()))
        } else {
            batch.update(oldWalletRef, mapOf("balance" to FieldValue.increment(oldAmount), "updatedAt" to FieldValue.serverTimestamp()))
            batch.update(newWalletRef, mapOf("balance" to FieldValue.increment(-asset.amount), "updatedAt" to FieldValue.serverTimestamp()))
        }
        batch.update(assetRef, mapOf(
            "name" to asset.name, "category" to asset.category, "amount" to asset.amount,
            "sourceId" to asset.sourceId, "sourceName" to asset.sourceName, "notes" to asset.notes,
            "updatedAt" to FieldValue.serverTimestamp(),
        ))
        batch.commit()
        activityLog.log(uid, ActivityLogType.asset, ActivityLogAction.edit, "Updated asset: ${asset.name}", asset.amount)
    }

    fun delete(uid: String, assetId: String, sourceId: String, amount: Double) {
        if (sourceId.isEmpty()) {
            col(uid).document(assetId).delete()
        } else {
            val batch = db.batch()
            val walletRef = db.collection("users").document(uid).collection("wallets").document(sourceId)
            batch.update(walletRef, mapOf("balance" to FieldValue.increment(amount), "updatedAt" to FieldValue.serverTimestamp()))
            batch.delete(col(uid).document(assetId))
            batch.commit()
        }
        activityLog.log(uid, ActivityLogType.asset, ActivityLogAction.delete, "Deleted asset", amount)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "feat: add AssetRepository"
```

### Task 13: Create ReceivableRepository & ReceivablePaymentRepository

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/repository/ReceivableRepository.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/repository/ReceivablePaymentRepository.kt`

- [ ] **Step 1: Implement ReceivableRepository**

```kotlin
package com.darskie.budgybydarskie.data.repository

import com.darskie.budgybydarskie.data.model.ActivityLogAction
import com.darskie.budgybydarskie.data.model.ActivityLogType
import com.darskie.budgybydarskie.data.model.Receivable
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ReceivableRepository @Inject constructor(
    private val db: FirebaseFirestore,
    private val activityLog: ActivityLogRepository,
) {
    private fun col(uid: String) = db.collection("users").document(uid).collection("receivables")

    fun subscribe(uid: String, year: Int, onChange: (List<Receivable>) -> Unit): ListenerRegistration {
        return col(uid)
            .whereEqualTo("year", year)
            .addSnapshotListener { snapshot, _ ->
                val items = snapshot?.documents
                    ?.mapNotNull { it.toObject(Receivable::class.java) }
                    ?.sortedBy { it.order }
                    ?: emptyList()
                onChange(items)
            }
    }

    fun add(uid: String, receivable: Receivable): String {
        val docId = col(uid).document().id
        val ref = col(uid).document(docId)
        val data = mapOf(
            "name" to receivable.name, "description" to receivable.receivableDescription,
            "amount" to receivable.amount, "sourceId" to receivable.sourceId,
            "sourceName" to receivable.sourceName, "isReimbursement" to receivable.isReimbursement,
            "notes" to receivable.notes, "year" to receivable.year,
            "order" to System.currentTimeMillis().toDouble(), "totalPaid" to 0.0,
            "createdAt" to FieldValue.serverTimestamp(), "updatedAt" to FieldValue.serverTimestamp(),
        )

        if (receivable.sourceId.isNotEmpty()) {
            val batch = db.batch()
            val walletRef = db.collection("users").document(uid).collection("wallets").document(receivable.sourceId)
            batch.update(walletRef, mapOf("balance" to FieldValue.increment(-receivable.amount), "updatedAt" to FieldValue.serverTimestamp()))
            batch.set(ref, data)
            batch.commit()
        } else {
            ref.set(data)
        }
        activityLog.log(uid, ActivityLogType.receivable, ActivityLogAction.add, "Added receivable: ${receivable.name}", receivable.amount)
        return docId
    }

    fun update(uid: String, receivableId: String, data: Map<String, Any>) {
        val mutableData = data.toMutableMap()
        mutableData["updatedAt"] = FieldValue.serverTimestamp()
        col(uid).document(receivableId).update(mutableData)
        activityLog.log(uid, ActivityLogType.receivable, ActivityLogAction.edit, "Updated receivable")
    }

    fun delete(uid: String, receivableId: String, sourceId: String, amount: Double) {
        if (sourceId.isNotEmpty()) {
            val batch = db.batch()
            val walletRef = db.collection("users").document(uid).collection("wallets").document(sourceId)
            batch.update(walletRef, mapOf("balance" to FieldValue.increment(amount), "updatedAt" to FieldValue.serverTimestamp()))
            batch.delete(col(uid).document(receivableId))
            batch.commit()
        } else {
            col(uid).document(receivableId).delete()
        }
        activityLog.log(uid, ActivityLogType.receivable, ActivityLogAction.delete, "Deleted receivable", amount)
    }
}
```

- [ ] **Step 2: Implement ReceivablePaymentRepository**

```kotlin
package com.darskie.budgybydarskie.data.repository

import com.darskie.budgybydarskie.data.model.ActivityLogAction
import com.darskie.budgybydarskie.data.model.ActivityLogType
import com.darskie.budgybydarskie.data.model.PaymentDestination
import com.darskie.budgybydarskie.data.model.ReceivablePayment
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ReceivablePaymentRepository @Inject constructor(
    private val db: FirebaseFirestore,
    private val activityLog: ActivityLogRepository,
) {
    private fun col(uid: String, receivableId: String) =
        db.collection("users").document(uid).collection("receivables").document(receivableId).collection("payments")

    fun subscribe(uid: String, receivableId: String, onChange: (List<ReceivablePayment>) -> Unit): ListenerRegistration {
        return col(uid, receivableId)
            .orderBy("createdAt", com.google.firebase.firestore.Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, _ ->
                val payments = snapshot?.documents
                    ?.mapNotNull { it.toObject(ReceivablePayment::class.java) }
                    ?: emptyList()
                onChange(payments)
            }
    }

    fun add(uid: String, receivableId: String, payment: ReceivablePayment, destinations: List<PaymentDestination>) {
        val batch = db.batch()

        // Credit destination wallets
        for (dest in destinations) {
            val walletRef = db.collection("users").document(uid).collection("wallets").document(dest.walletId)
            batch.update(walletRef, mapOf("balance" to FieldValue.increment(dest.amount), "updatedAt" to FieldValue.serverTimestamp()))
        }

        // Update receivable totalPaid
        val receivableRef = db.collection("users").document(uid).collection("receivables").document(receivableId)
        batch.update(receivableRef, mapOf("totalPaid" to FieldValue.increment(payment.amount), "updatedAt" to FieldValue.serverTimestamp()))

        // Add payment record
        val destData = destinations.map { mapOf("walletId" to it.walletId, "walletName" to it.walletName, "amount" to it.amount) }
        val paymentRef = col(uid, receivableId).document()
        batch.set(paymentRef, mapOf(
            "amount" to payment.amount,
            "date" to (payment.date ?: Timestamp.now()),
            "destinations" to destData,
            "notes" to payment.notes,
            "createdAt" to FieldValue.serverTimestamp(),
        ))

        batch.commit()
        activityLog.log(uid, ActivityLogType.payment, ActivityLogAction.add, "Received payment", payment.amount)
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: add ReceivableRepository and ReceivablePaymentRepository"
```

### Task 14: Create Remaining Repositories

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/repository/WalletTransactionRepository.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/repository/WatchlistRepository.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/repository/ProfitAllocationRepository.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/repository/SavingsRepository.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/data/repository/AuthRepository.kt`

- [ ] **Step 1: Implement WalletTransactionRepository**

```kotlin
package com.darskie.budgybydarskie.data.repository

import com.darskie.budgybydarskie.data.model.*
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WalletTransactionRepository @Inject constructor(
    private val db: FirebaseFirestore,
) {
    fun subscribe(
        uid: String, walletId: String, year: Int,
        onChange: (List<WalletTransaction>) -> Unit,
    ): List<ListenerRegistration> {
        val listeners = mutableListOf<ListenerRegistration>()
        val allTxs = mutableMapOf<String, List<WalletTransaction>>()

        fun emit() {
            val combined = allTxs.values.flatten().sortedByDescending { it.date }
            onChange(combined)
        }

        // Deposits
        listeners += db.collection("users").document(uid).collection("deposits")
            .whereEqualTo("walletId", walletId).whereEqualTo("year", year)
            .addSnapshotListener { snap, _ ->
                allTxs["deposits"] = snap?.documents?.mapNotNull { it.toObject(Deposit::class.java) }?.map {
                    WalletTransaction(it.id, WalletTransactionType.deposit, it.sourceLabel, it.notes, it.amount, it.dateAsDate)
                } ?: emptyList()
                emit()
            }

        // Expenses
        listeners += db.collection("users").document(uid).collection("expenses")
            .whereEqualTo("sourceId", walletId).whereEqualTo("year", year)
            .addSnapshotListener { snap, _ ->
                allTxs["expenses"] = snap?.documents?.mapNotNull { it.toObject(Expense::class.java) }?.map {
                    WalletTransaction(it.id, WalletTransactionType.expense, it.expenseDescription, it.notes, it.amount, it.dateAsDate)
                } ?: emptyList()
                emit()
            }

        // Investments
        listeners += db.collection("users").document(uid).collection("investments")
            .whereEqualTo("sourceId", walletId).whereEqualTo("year", year)
            .addSnapshotListener { snap, _ ->
                allTxs["investments"] = snap?.documents?.mapNotNull { it.toObject(Investment::class.java) }?.map {
                    WalletTransaction(it.id, WalletTransactionType.investment, it.stock, it.remarks, it.amountPhp, it.dateAsDate)
                } ?: emptyList()
                emit()
            }

        // Assets
        listeners += db.collection("users").document(uid).collection("assets")
            .whereEqualTo("sourceId", walletId).whereEqualTo("year", year)
            .addSnapshotListener { snap, _ ->
                allTxs["assets"] = snap?.documents?.mapNotNull { it.toObject(Asset::class.java) }?.map {
                    WalletTransaction(it.id, WalletTransactionType.asset, it.name, it.notes, it.amount, it.createdAt?.toDate() ?: java.util.Date())
                } ?: emptyList()
                emit()
            }

        // Withdrawals (source side)
        listeners += db.collection("users").document(uid).collection("withdrawals")
            .whereEqualTo("bankWalletId", walletId).whereEqualTo("year", year)
            .addSnapshotListener { snap, _ ->
                allTxs["withdrawals_out"] = snap?.documents?.mapNotNull { it.toObject(Withdrawal::class.java) }?.map {
                    WalletTransaction(it.id, WalletTransactionType.withdrawal, "To ${it.cashWalletName}", "Fee: ${it.fee}", it.amount + it.fee, it.dateAsDate)
                } ?: emptyList()
                emit()
            }

        // Withdrawals (dest side)
        listeners += db.collection("users").document(uid).collection("withdrawals")
            .whereEqualTo("cashWalletId", walletId).whereEqualTo("year", year)
            .addSnapshotListener { snap, _ ->
                allTxs["withdrawals_in"] = snap?.documents?.mapNotNull { it.toObject(Withdrawal::class.java) }?.map {
                    WalletTransaction(it.id, WalletTransactionType.withdrawalIn, "From ${it.bankWalletName}", "", it.amount, it.dateAsDate)
                } ?: emptyList()
                emit()
            }

        return listeners
    }
}
```

- [ ] **Step 2: Implement WatchlistRepository**

```kotlin
package com.darskie.budgybydarskie.data.repository

import com.darskie.budgybydarskie.data.model.WatchlistItem
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WatchlistRepository @Inject constructor(
    private val db: FirebaseFirestore,
) {
    private fun col(uid: String) = db.collection("users").document(uid).collection("watchlist")

    fun subscribe(uid: String, onChange: (List<WatchlistItem>) -> Unit): ListenerRegistration {
        return col(uid).addSnapshotListener { snapshot, _ ->
            val items = snapshot?.documents?.mapNotNull { it.toObject(WatchlistItem::class.java) }
                ?.sortedBy { it.order } ?: emptyList()
            onChange(items)
        }
    }

    fun add(uid: String, item: WatchlistItem): String {
        val docId = col(uid).document().id
        col(uid).document(docId).set(mapOf(
            "symbol" to item.symbol, "name" to item.name, "type" to item.type,
            "order" to System.currentTimeMillis().toDouble(),
            "createdAt" to FieldValue.serverTimestamp(),
        ))
        return docId
    }

    fun delete(uid: String, itemId: String) {
        col(uid).document(itemId).delete()
    }
}
```

- [ ] **Step 3: Implement ProfitAllocationRepository and SavingsRepository**

```kotlin
// ProfitAllocationRepository.kt
package com.darskie.budgybydarskie.data.repository

import com.darskie.budgybydarskie.data.model.ProfitAllocation
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ProfitAllocationRepository @Inject constructor(private val db: FirebaseFirestore) {
    private fun col(uid: String) = db.collection("users").document(uid).collection("profitAllocations")

    fun subscribe(uid: String, year: Int, onChange: (List<ProfitAllocation>) -> Unit): ListenerRegistration {
        return col(uid).whereEqualTo("year", year).addSnapshotListener { snap, _ ->
            onChange(snap?.documents?.mapNotNull { it.toObject(ProfitAllocation::class.java) } ?: emptyList())
        }
    }

    fun add(uid: String, allocation: ProfitAllocation): String {
        val docId = col(uid).document().id
        col(uid).document(docId).set(mapOf(
            "label" to allocation.label, "destType" to allocation.destType,
            "amount" to allocation.amount, "year" to allocation.year,
            "createdAt" to FieldValue.serverTimestamp(), "updatedAt" to FieldValue.serverTimestamp(),
        ))
        return docId
    }

    fun update(uid: String, id: String, data: Map<String, Any>) {
        val d = data.toMutableMap(); d["updatedAt"] = FieldValue.serverTimestamp()
        col(uid).document(id).update(d)
    }

    fun delete(uid: String, id: String) { col(uid).document(id).delete() }
}
```

```kotlin
// SavingsRepository.kt
package com.darskie.budgybydarskie.data.repository

import com.darskie.budgybydarskie.data.model.SavingsBreakdown
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SavingsRepository @Inject constructor(private val db: FirebaseFirestore) {
    private fun col(uid: String) = db.collection("users").document(uid).collection("savingsBreakdown")

    fun subscribe(uid: String, year: Int, onChange: (List<SavingsBreakdown>) -> Unit): ListenerRegistration {
        return col(uid).whereEqualTo("year", year).addSnapshotListener { snap, _ ->
            onChange(snap?.documents?.mapNotNull { it.toObject(SavingsBreakdown::class.java) } ?: emptyList())
        }
    }

    fun add(uid: String, item: SavingsBreakdown): String {
        val docId = col(uid).document().id
        col(uid).document(docId).set(mapOf(
            "label" to item.label, "amount" to item.amount, "year" to item.year,
            "updatedAt" to FieldValue.serverTimestamp(),
        ))
        return docId
    }

    fun update(uid: String, id: String, data: Map<String, Any>) {
        val d = data.toMutableMap(); d["updatedAt"] = FieldValue.serverTimestamp()
        col(uid).document(id).update(d)
    }

    fun delete(uid: String, id: String) { col(uid).document(id).delete() }
}
```

- [ ] **Step 4: Implement AuthRepository**

```kotlin
package com.darskie.budgybydarskie.data.repository

import android.content.Context
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.GoogleAuthProvider
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepository @Inject constructor(
    private val auth: FirebaseAuth,
    @ApplicationContext private val context: Context,
) {
    val currentUser: FirebaseUser? get() = auth.currentUser
    val uid: String? get() = auth.currentUser?.uid

    val authState: Flow<FirebaseUser?> = callbackFlow {
        val listener = FirebaseAuth.AuthStateListener { trySend(it.currentUser) }
        auth.addAuthStateListener(listener)
        awaitClose { auth.removeAuthStateListener(listener) }
    }

    suspend fun signInWithGoogle(webClientId: String): FirebaseUser {
        val credentialManager = CredentialManager.create(context)
        val googleIdOption = GetGoogleIdOption.Builder()
            .setFilterByAuthorizedAccounts(false)
            .setServerClientId(webClientId)
            .build()

        val request = GetCredentialRequest.Builder()
            .addCredentialOption(googleIdOption)
            .build()

        val result = credentialManager.getCredential(context, request)
        val credential = result.credential
        val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(credential.data)
        val firebaseCredential = GoogleAuthProvider.getCredential(googleIdTokenCredential.idToken, null)
        val authResult = auth.signInWithCredential(firebaseCredential).await()
        return authResult.user!!
    }

    fun signOut() {
        auth.signOut()
    }

    suspend fun switchAccount(webClientId: String): FirebaseUser {
        auth.signOut()
        return signInWithGoogle(webClientId)
    }
}
```

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: add remaining repositories — WalletTransaction, Watchlist, ProfitAllocation, Savings, Auth"
```

---

## Phase 6: Theme & Shared UI Components

### Task 15: Create Material 3 Theme

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/theme/Theme.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/theme/Color.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/theme/Type.kt`

- [ ] **Step 1: Create Color.kt**

```kotlin
package com.darskie.budgybydarskie.ui.theme

import androidx.compose.ui.graphics.Color

// Module colors (matching iOS AppTheme)
val AccentBlue = Color(0xFF2196F3)
val WalletIndigo = Color(0xFF3F51B5)
val ExpenseRed = Color(0xFFF44336)
val InvestmentPurple = Color(0xFF9C27B0)
val AssetOrange = Color(0xFFFF9800)
val BuySellTeal = Color(0xFF009688)
val ReceivableCyan = Color(0xFF00BCD4)
val AnalyticsPurple = Color(0xFF9C27B0)

// Semantic
val PositiveGreen = Color(0xFF4CAF50)
val NegativeRed = Color(0xFFF44336)
val WarningOrange = Color(0xFFFF9800)
```

- [ ] **Step 2: Create Type.kt**

```kotlin
package com.darskie.budgybydarskie.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

val Typography = Typography(
    headlineLarge = TextStyle(fontWeight = FontWeight.Bold, fontSize = 28.sp),
    headlineMedium = TextStyle(fontWeight = FontWeight.Bold, fontSize = 24.sp),
    titleLarge = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 20.sp),
    titleMedium = TextStyle(fontWeight = FontWeight.SemiBold, fontSize = 16.sp),
    bodyLarge = TextStyle(fontSize = 16.sp),
    bodyMedium = TextStyle(fontSize = 14.sp),
    bodySmall = TextStyle(fontSize = 12.sp),
    labelLarge = TextStyle(fontWeight = FontWeight.Medium, fontSize = 14.sp),
    labelSmall = TextStyle(fontSize = 11.sp, fontFamily = FontFamily.Monospace),
)
```

- [ ] **Step 3: Create Theme.kt**

```kotlin
package com.darskie.budgybydarskie.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext

private val DarkColorScheme = darkColorScheme(
    primary = AccentBlue,
    secondary = WalletIndigo,
    tertiary = InvestmentPurple,
    error = NegativeRed,
)

private val LightColorScheme = lightColorScheme(
    primary = AccentBlue,
    secondary = WalletIndigo,
    tertiary = InvestmentPurple,
    error = NegativeRed,
)

@Composable
fun BudgyTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit,
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content,
    )
}
```

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: add Material 3 theme with module colors"
```

### Task 16: Create Shared UI Components

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/components/CurrencyText.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/components/EmptyStateView.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/components/CategoryBadge.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/components/StatusBadge.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/components/ConfirmationDialog.kt`

- [ ] **Step 1: Create all shared components**

Each component is a standalone Composable matching the iOS equivalent. Create each file with its `@Composable` function:

**CurrencyText.kt:**
```kotlin
package com.darskie.budgybydarskie.ui.components

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextAlign
import com.darskie.budgybydarskie.util.formatPhp

@Composable
fun CurrencyText(
    amount: Double,
    modifier: Modifier = Modifier,
    masked: Boolean = false,
    style: androidx.compose.ui.text.TextStyle = MaterialTheme.typography.bodyMedium,
) {
    Text(
        text = if (masked) "••••••" else formatPhp(amount),
        style = style.copy(fontFamily = FontFamily.Monospace),
        modifier = modifier,
    )
}
```

**EmptyStateView.kt:**
```kotlin
package com.darskie.budgybydarskie.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Inbox
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

@Composable
fun EmptyStateView(
    icon: ImageVector = Icons.Default.Inbox,
    title: String,
    message: String,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier.fillMaxWidth().padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Icon(icon, contentDescription = null, modifier = Modifier.size(64.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.height(16.dp))
        Text(title, style = MaterialTheme.typography.titleMedium, textAlign = TextAlign.Center)
        Spacer(Modifier.height(8.dp))
        Text(message, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
    }
}
```

**CategoryBadge.kt:**
```kotlin
package com.darskie.budgybydarskie.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

@Composable
fun CategoryBadge(label: String, color: Color, modifier: Modifier = Modifier) {
    Text(
        text = label,
        style = MaterialTheme.typography.labelSmall,
        color = color,
        modifier = modifier
            .background(color.copy(alpha = 0.15f), RoundedCornerShape(8.dp))
            .padding(horizontal = 8.dp, vertical = 4.dp),
    )
}
```

**StatusBadge.kt:**
```kotlin
package com.darskie.budgybydarskie.ui.components

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.darskie.budgybydarskie.data.model.BuySellStatus

@Composable
fun StatusBadge(status: BuySellStatus, modifier: Modifier = Modifier) {
    CategoryBadge(label = status.label, color = status.color, modifier = modifier)
}
```

**ConfirmationDialog.kt:**
```kotlin
package com.darskie.budgybydarskie.ui.components

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable

@Composable
fun ConfirmationDialog(
    title: String,
    message: String,
    confirmText: String = "Delete",
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = { Text(message) },
        confirmButton = { TextButton(onClick = onConfirm) { Text(confirmText) } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "feat: add shared UI components — CurrencyText, EmptyState, badges, dialog"
```

---

## Phase 7: Navigation & App Shell

### Task 17: Create Navigation Structure and MainActivity

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/MainActivity.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/navigation/NavGraph.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/navigation/Screen.kt`

- [ ] **Step 1: Create Screen.kt (route definitions)**

```kotlin
package com.darskie.budgybydarskie.navigation

sealed class Screen(val route: String) {
    object Login : Screen("login")
    object Main : Screen("main")
    object WalletHistory : Screen("wallet_history/{walletId}") {
        fun createRoute(walletId: String) = "wallet_history/$walletId"
    }
    object Watchlist : Screen("watchlist")
    object Assets : Screen("assets")
    object BuySell : Screen("buysell")
    object BuySellDetail : Screen("buysell_detail/{txId}") {
        fun createRoute(txId: String) = "buysell_detail/$txId"
    }
    object Receivables : Screen("receivables")
    object PersonReceivables : Screen("person_receivables/{name}") {
        fun createRoute(name: String) = "person_receivables/$name"
    }
    object PaymentHistory : Screen("payment_history/{receivableId}") {
        fun createRoute(receivableId: String) = "payment_history/$receivableId"
    }
    object Analytics : Screen("analytics")
    object ActivityLog : Screen("activity_log")
    object Settings : Screen("settings")
}
```

- [ ] **Step 2: Create NavGraph.kt**

```kotlin
package com.darskie.budgybydarskie.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.darskie.budgybydarskie.ui.activitylog.ActivityLogScreen
import com.darskie.budgybydarskie.ui.analytics.AnalyticsScreen
import com.darskie.budgybydarskie.ui.assets.AssetsScreen
import com.darskie.budgybydarskie.ui.auth.LoginScreen
import com.darskie.budgybydarskie.ui.buysell.BuySellDetailScreen
import com.darskie.budgybydarskie.ui.buysell.BuySellScreen
import com.darskie.budgybydarskie.ui.investments.WatchlistScreen
import com.darskie.budgybydarskie.ui.main.MainScreen
import com.darskie.budgybydarskie.ui.receivables.PaymentHistoryScreen
import com.darskie.budgybydarskie.ui.receivables.PersonReceivablesScreen
import com.darskie.budgybydarskie.ui.receivables.ReceivablesScreen
import com.darskie.budgybydarskie.ui.settings.SettingsScreen
import com.darskie.budgybydarskie.ui.finance.WalletTransactionHistoryScreen

@Composable
fun BudgyNavGraph(navController: NavHostController, startDestination: String) {
    NavHost(navController = navController, startDestination = startDestination) {
        composable(Screen.Login.route) { LoginScreen(navController) }
        composable(Screen.Main.route) { MainScreen(navController) }
        composable(
            Screen.WalletHistory.route,
            arguments = listOf(navArgument("walletId") { type = NavType.StringType })
        ) { entry ->
            WalletTransactionHistoryScreen(navController, entry.arguments?.getString("walletId") ?: "")
        }
        composable(Screen.Watchlist.route) { WatchlistScreen(navController) }
        composable(Screen.Assets.route) { AssetsScreen(navController) }
        composable(Screen.BuySell.route) { BuySellScreen(navController) }
        composable(
            Screen.BuySellDetail.route,
            arguments = listOf(navArgument("txId") { type = NavType.StringType })
        ) { entry ->
            BuySellDetailScreen(navController, entry.arguments?.getString("txId") ?: "")
        }
        composable(Screen.Receivables.route) { ReceivablesScreen(navController) }
        composable(
            Screen.PersonReceivables.route,
            arguments = listOf(navArgument("name") { type = NavType.StringType })
        ) { entry ->
            PersonReceivablesScreen(navController, entry.arguments?.getString("name") ?: "")
        }
        composable(
            Screen.PaymentHistory.route,
            arguments = listOf(navArgument("receivableId") { type = NavType.StringType })
        ) { entry ->
            PaymentHistoryScreen(navController, entry.arguments?.getString("receivableId") ?: "")
        }
        composable(Screen.Analytics.route) { AnalyticsScreen(navController) }
        composable(Screen.ActivityLog.route) { ActivityLogScreen(navController) }
        composable(Screen.Settings.route) { SettingsScreen(navController) }
    }
}
```

- [ ] **Step 3: Create MainActivity.kt**

```kotlin
package com.darskie.budgybydarskie

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.compose.rememberNavController
import com.darskie.budgybydarskie.navigation.BudgyNavGraph
import com.darskie.budgybydarskie.navigation.Screen
import com.darskie.budgybydarskie.ui.auth.AuthViewModel
import com.darskie.budgybydarskie.ui.theme.BudgyTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            val authViewModel: AuthViewModel = hiltViewModel()
            val authState by authViewModel.authState.collectAsState()

            BudgyTheme {
                val navController = rememberNavController()
                val startDestination = if (authState != null) Screen.Main.route else Screen.Login.route
                BudgyNavGraph(navController = navController, startDestination = startDestination)
            }
        }
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: add navigation graph, route definitions, and MainActivity"
```

---

## Phase 8-20: UI Screens (ViewModels + Composables)

Each remaining phase follows the same pattern: create the ViewModel, then create the Composable screens and form sheets. Below is the task list for each feature. Each task should create the ViewModel and all associated screens as shown in the architecture diagram.

### Task 18: AuthViewModel & LoginScreen

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/auth/AuthViewModel.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/auth/LoginScreen.kt`

The AuthViewModel exposes `authState: StateFlow<FirebaseUser?>`, `isLoading`, `errorMessage`, and `signIn()`, `signOut()`, `switchAccount()` methods. LoginScreen shows a gradient background with Google Sign-In button, matching iOS LoginView.

### Task 19: MainScreen with Bottom Navigation

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/main/MainScreen.kt`

4-tab bottom nav: Dashboard, Finance, Investments, More. Uses `NavigationBar` + `NavigationBarItem` from Material 3. Each tab hosts its screen composable.

### Task 20: DashboardScreen & DashboardViewModel

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/dashboard/DashboardViewModel.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/dashboard/DashboardScreen.kt`

ViewModel subscribes to wallets, expenses, investments, buySell, assets, receivables. Computes grand total, stat card values, expense by category, monthly expenses. Screen renders stat cards in 2x2 grid, Vico donut chart, Vico bar chart, FAB for quick expense.

### Task 21: FinanceScreen (Wallets + Expenses)

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/finance/FinanceScreen.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/finance/WalletsSection.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/finance/WalletViewModel.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/finance/WalletFormSheet.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/finance/DepositFormSheet.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/finance/TransferFormSheet.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/finance/WalletTransactionHistoryScreen.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/finance/ExpensesSection.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/finance/ExpenseViewModel.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/finance/ExpenseFormSheet.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/finance/ExpenseDetailSheet.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/finance/ExpenseExportSheet.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/finance/ReceiptScannerScreen.kt`

Segmented tab (TabRow) toggles between WalletsSection and ExpensesSection. Wallets: grouped by Bank/Cash, long-press context menu, total balance footer. Expenses: category filter chips, period filter, sort options, grouped by date, receipt scanner via ML Kit.

### Task 22: InvestmentsScreen & InvestmentViewModel

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/investments/InvestmentViewModel.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/investments/InvestmentsScreen.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/investments/InvestmentFormSheet.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/investments/TPSLFormSheet.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/investments/PortfolioSummaryCards.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/investments/WatchlistScreen.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/investments/AddToWatchlistSheet.kt`

Tab filter (All/Crypto/Stock/Other), portfolio summary cards, investment list with context menu, TP/SL bottom sheet, watchlist screen.

### Task 23: BuySellScreen & BuySellViewModel

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/buysell/BuySellViewModel.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/buysell/BuySellScreen.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/buysell/BuySellFormSheet.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/buysell/BuySellDetailScreen.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/buysell/SoldFormSheet.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/buysell/ProfitAllocationSheet.kt`

Profit summary, status counts, filter/sort, multi-source funding form, sold form with destination routing, profit allocation tracking.

### Task 24: ReceivablesScreen & ReceivableViewModel

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/receivables/ReceivableViewModel.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/receivables/ReceivablesScreen.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/receivables/ReceivableFormSheet.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/receivables/PersonReceivablesScreen.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/receivables/PaymentHistoryScreen.kt`

Two tabs (Ongoing/Completed), grouped by person, payment history, record payment with multi-destination routing.

### Task 25: AssetsScreen & AssetViewModel

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/assets/AssetViewModel.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/assets/AssetsScreen.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/assets/AssetFormSheet.kt`

Categorized list, long-press actions, form with category picker and source wallet.

### Task 26: AnalyticsScreen & AnalyticsViewModel

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/analytics/AnalyticsViewModel.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/analytics/AnalyticsScreen.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/analytics/OverallAnalyticsView.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/analytics/ExpenseAnalyticsView.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/analytics/InvestmentAnalyticsView.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/analytics/BuySellAnalyticsView.kt`

4-tab analytics with date range filters. Vico charts: line (overall trend), donut (category breakdown), bar (monthly). Custom date range picker.

### Task 27: ActivityLogScreen & ActivityLogViewModel

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/activitylog/ActivityLogViewModel.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/activitylog/ActivityLogScreen.kt`

Reverse chronological list, filter chips by type and action, color-coded entries.

### Task 28: SettingsScreen & SettingsViewModel

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/settings/SettingsViewModel.kt`
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/settings/SettingsScreen.kt`

Appearance mode toggle (System/Light/Dark), expense reminder scheduling with WorkManager, about section.

### Task 29: MoreMenuScreen

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/ui/main/MoreMenuScreen.kt`

Profile card (name, email, photo from Coil, account switch button), navigation items to Assets/BuySell/Receivables/Analytics/ActivityLog/Settings, sign out button.

---

## Phase 9: Deep Links & Notifications

### Task 30: Deep Link Handler

**Files:**
- Modify: `app/src/main/java/com/darskie/budgybydarskie/MainActivity.kt`

Handle `budgy://add-expense` and `budgy://dashboard` intents in `onCreate` and `onNewIntent`. Navigate to appropriate screen via NavController.

### Task 31: Expense Reminder Notifications

**Files:**
- Create: `app/src/main/java/com/darskie/budgybydarskie/util/ReminderWorker.kt`

WorkManager PeriodicWorkRequest to show notification at scheduled times. Uses `NotificationCompat.Builder` with the same reminder messages as iOS.

---

## Phase 10: Final Integration

### Task 32: Build Verification & Smoke Test

- [ ] **Step 1: Verify project compiles**

```bash
cd /Users/daryll/Desktop/BudgyByDarskieAndroid
./gradlew assembleDebug
```

- [ ] **Step 2: Fix any compilation errors**

- [ ] **Step 3: Run on emulator or device**

```bash
./gradlew installDebug
adb shell am start -n com.darskie.budgybydarskie/.MainActivity
```

- [ ] **Step 4: Verify Firestore data loads (same data as iOS app)**

- [ ] **Step 5: Final commit**

```bash
git add -A && git commit -m "feat: BudgyByDarskie Android v1.0.0 — full feature parity with iOS"
```
