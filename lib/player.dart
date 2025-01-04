const povertyScore = 14;

class Player {
  String name;
  int score = 0;

  Player({required this.name});

  bool hasPoverty() {
    return score == povertyScore;
  }

  bool isDead() {
    return score > povertyScore;
  }

  void addScore() {
    if (score < 100) score++;
  }

  void subtractScore() {
    if (score > 0) score--;
  }
}
