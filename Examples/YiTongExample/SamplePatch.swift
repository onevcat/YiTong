import Foundation

enum SamplePatch {
  static let multiFile = """
  diff --git a/Sources/App/Counter.swift b/Sources/App/Counter.swift
  index 1111111..2222222 100644
  --- a/Sources/App/Counter.swift
  +++ b/Sources/App/Counter.swift
  @@ -1,7 +1,11 @@
   import Foundation
   
   struct Counter {
  -  var value: Int
  +  private(set) var value: Int
  +
  +  mutating func reset() {
  +    value = 0
  +  }
   
     mutating func increment() {
       value += 1
  diff --git a/Sources/App/AppView.swift b/Sources/App/AppView.swift
  index 3333333..4444444 100644
  --- a/Sources/App/AppView.swift
  +++ b/Sources/App/AppView.swift
  @@ -1,8 +1,12 @@
   import SwiftUI
   
   struct AppView: View {
  -  @State private var count = 0
  +  @State private var counter = Counter(value: 0)
   
     var body: some View {
  -    Text("\\(count)")
  +    VStack(spacing: 12) {
  +      Text("\\(counter.value)")
  +      Button("Reset") { counter.reset() }
  +    }
     }
   }
  """
}
