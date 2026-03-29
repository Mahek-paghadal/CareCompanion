import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppointmentDetailsPage extends StatelessWidget {
  static String doctorName = "";
  static DateTime? appointmentDate;
  static TimeOfDay? appointmentTime;
  static String meetingID = "";

  const AppointmentDetailsPage({super.key});

  void joinMeeting() async {
    String jitsiMeetingUrl = "https://meet.jit.si/$meetingID";
    Uri meetingUri = Uri.parse(jitsiMeetingUrl);

    if (await canLaunchUrl(meetingUri)) {
      await launchUrl(meetingUri, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not launch $jitsiMeetingUrl";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Light background color
      appBar: AppBar(
        title: const Text("Appointment Details"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Doctor Avatar
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue[100],
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Doctor Name
                  Text(
                    "Dr. $doctorName",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Appointment Date & Time
                  if (appointmentDate != null && appointmentTime != null)
                    Column(
                      children: [
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.calendar_today,
                            color: Colors.blueAccent,
                          ),
                          title: Text(
                            "Date: ${appointmentDate!.day}/${appointmentDate!.month}/${appointmentDate!.year}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.access_time,
                            color: Colors.blueAccent,
                          ),
                          title: Text(
                            "Time: ${appointmentTime!.format(context)}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const Divider(),
                      ],
                    ),
                  const SizedBox(height: 20),
                  // Join Meeting Button
                  ElevatedButton(
                    onPressed: joinMeeting,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: const Text(
                      "Join Now",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
