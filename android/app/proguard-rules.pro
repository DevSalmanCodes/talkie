-keep class java.beans.ConstructorProperties { *; }
-keep class java.beans.Transient { *; }
-keep class org.w3c.dom.bootstrap.DOMImplementationRegistry { *; }
# You might also see specific rules related to com.fasterxml.jackson.databind
# If there are -dontwarn rules, add them too.-keep class com.fasterxml.jackson.** { *; }
-dontwarn com.fasterxml.jackson.**