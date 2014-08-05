uMobile iOS App
===============

**uMobile** is the mobilization of [uPortal](https://github.com/Jasig/uPortal). It
brings campus applications, content, and data to mobile devices. For additional
information, please refer to the [Apereo uMobile
page](http://www.apereo.org/umobile).

This app is a native Objective-C implementation of uMobile for iOS
devices—everything from iPod Touch on iOS 6 to iPad Air running iOS 8. This
means native iOS idioms, features, UI components, and frameworks are readily
available and easily integrated.

Getting Started
---------------

Clone this project and open `uMobile.xcodeproj` in Xcode (available on the Mac
app store if you don't already have it).

Then, select an iOS Simulator from the top toolbar and click the Run icon (▶)
just to the left of it to compile and run.

That's it!

Customization
-------------

This app has been designed from the ground up to be modular and easily
customizable. Everything you need to change, other than the launch images and
app icon, are found within the `Constants.h` and `Constants.m` files.

### [Constants.h](uMobile/Constants.h)
Global colors are defined here.
* `kPrimaryTintColor` is used for the portlet section headers and other UI
  elements
* `kSecondayTintColor` is mainly used for background colors
* `kTextTintColor` is for non-button UI text; you may want to set it the same as
  `kPrimaryTintColor`

### [Constants.m](uMobile/Constants.m)
Change the following values to point to your own uPortal instance:
* `kBaseURL` is the main URL for your uPortal instance, such as
  `https://yourportal.example.edu`.
* `kCasServer` will allow you to log in if you're running CAS

> Note: if you use a form of authentication / single sign-on other than CAS,
> you'll have to subclass the `Authenticator` class and override its public API
> (the methods listed in `Authenticator.h`).

Other constants:
* `kTitle` is the title of the app displayed throughout
* `kForgotPasswordURL` can be used to pop the user over to Safari
* `kUsernamePlaceholder` is the placeholder text for the Username text field on
  the Login view

Getting Involved
----------------
For any questions, comments, or feedback on use or development of this product,
please sign up on the [uMobile mailing
lists](http://www.jasig.org/umobile/mailing-lists).

Screenshots!
------------
![Screenshot 2](https://raw.githubusercontent.com/Oakland-University/uMobile-iOS-app/9a07ccde1c7c447e121977334dce30a926beb669/uMobile/Screenshots/Screenshot%202.png)

<br />

![Screenshot 3](https://raw.githubusercontent.com/Oakland-University/uMobile-iOS-app/9a07ccde1c7c447e121977334dce30a926beb669/uMobile/Screenshots/Screenshot%203.png)
