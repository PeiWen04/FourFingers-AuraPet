class FeedbackModel {
  final String username;
  final String userImage;
  final String reportedDate;
  final String feedbackText;
  final double rating;
  final String? attachedImage;
  String status;

  FeedbackModel({
    required this.username,
    required this.userImage,
    required this.reportedDate,
    required this.feedbackText,
    required this.rating,
    this.attachedImage,
    this.status = 'Unsolved',
  });
}

