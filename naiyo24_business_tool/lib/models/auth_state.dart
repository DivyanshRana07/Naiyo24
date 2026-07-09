class AuthState {
  const AuthState({
    this.isLoggedIn = false,
    this.hasCompletedOnboarding = false,
    this.userEmail,
  });

  final bool isLoggedIn;
  final bool hasCompletedOnboarding;
  final String? userEmail;

  AuthState copyWith({
    bool? isLoggedIn,
    bool? hasCompletedOnboarding,
    String? userEmail,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  @override
  String toString() =>
      'AuthState(isLoggedIn: $isLoggedIn, hasCompletedOnboarding: $hasCompletedOnboarding, userEmail: $userEmail)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.isLoggedIn == isLoggedIn &&
        other.hasCompletedOnboarding == hasCompletedOnboarding &&
        other.userEmail == userEmail;
  }

  @override
  int get hashCode =>
      Object.hash(isLoggedIn, hasCompletedOnboarding, userEmail);
}
