import 'package:flutter/material.dart';
class SignUpFirstInterface extends StatefulWidget {
	const SignUpFirstInterface({super.key});
	@override
		SignUpFirstInterfaceState createState() => SignUpFirstInterfaceState();
	}
class SignUpFirstInterfaceState extends State<SignUpFirstInterface> {
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: SafeArea(
				child: Container(
					constraints: const BoxConstraints.expand(),
					color: Color(0xFFFFFFFF),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Expanded(
								child: IntrinsicHeight(
									child: Container(
										color: Color(0xFFFFFFFF),
										width: double.infinity,
										height: double.infinity,
										child: SingleChildScrollView(
											padding: const EdgeInsets.only( top: 28, bottom: 28, left: 18, right: 18),
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													IntrinsicHeight(
														child: Container(
															decoration: BoxDecoration(
																borderRadius: BorderRadius.circular(46),
																color: Color(0xFF243172),
															),
															width: double.infinity,
															child: Column(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	Container(
																		margin: const EdgeInsets.only( top: 22, left: 17),
																		width: 21,
																		height: 24,
																		child: Image.network(
																			"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/Y8FDqv2vvv/fhr8uoeu_expires_30_days.png",
																			fit: BoxFit.fill,
																		)
																	),
																	Container(
																		margin: const EdgeInsets.only( bottom: 73, left: 72),
																		child: Text(
																			"SELECT ROLE",
																			style: TextStyle(
																				color: Color(0xFFFFFFFF),
																				fontSize: 40,
																			),
																		),
																	),
																	IntrinsicHeight(
																		child: Container(
																			margin: const EdgeInsets.only( bottom: 16),
																			width: double.infinity,
																			child: Column(
																				children: [
																					InkWell(
																						onTap: () { print('Pressed'); },
																						child: IntrinsicWidth(
																							child: IntrinsicHeight(
																								child: Container(
																									decoration: BoxDecoration(
																										borderRadius: BorderRadius.circular(41),
																										color: Color(0xFF4795A3),
																									),
																									padding: const EdgeInsets.only( top: 29, bottom: 29, left: 72, right: 72),
																									child: Column(
																										crossAxisAlignment: CrossAxisAlignment.start,
																										children: [
																											Text(
																												"STUDENT",
																												style: TextStyle(
																													color: Color(0xFFFFFFFF),
																													fontSize: 24,
																												),
																											),
																										]
																									),
																								),
																							),
																						),
																					),
																				]
																			),
																		),
																	),
																	IntrinsicHeight(
																		child: Container(
																			margin: const EdgeInsets.only( bottom: 16),
																			width: double.infinity,
																			child: Column(
																				children: [
																					InkWell(
																						onTap: () { print('Pressed'); },
																						child: IntrinsicWidth(
																							child: IntrinsicHeight(
																								child: Container(
																									decoration: BoxDecoration(
																										borderRadius: BorderRadius.circular(41),
																										color: Color(0xFF4795A3),
																									),
																									padding: const EdgeInsets.only( top: 31, bottom: 31, left: 46, right: 46),
																									child: Column(
																										crossAxisAlignment: CrossAxisAlignment.start,
																										children: [
																											Text(
																												"BUS ATTENDANT",
																												style: TextStyle(
																													color: Color(0xFFFFFFFF),
																													fontSize: 20,
																												),
																											),
																										]
																									),
																								),
																							),
																						),
																					),
																				]
																			),
																		),
																	),
																	IntrinsicHeight(
																		child: Container(
																			margin: const EdgeInsets.only( bottom: 335),
																			width: double.infinity,
																			child: Column(
																				children: [
																					InkWell(
																						onTap: () { print('Pressed'); },
																						child: IntrinsicWidth(
																							child: IntrinsicHeight(
																								child: Container(
																									decoration: BoxDecoration(
																										borderRadius: BorderRadius.circular(41),
																										color: Color(0xFF4795A3),
																									),
																									padding: const EdgeInsets.only( top: 28, bottom: 28, left: 75, right: 75),
																									child: Column(
																										crossAxisAlignment: CrossAxisAlignment.start,
																										children: [
																											Text(
																												"DRIVER",
																												style: TextStyle(
																													color: Color(0xFFFFFFFF),
																													fontSize: 24,
																												),
																											),
																										]
																									),
																								),
																							),
																						),
																					),
																				]
																			),
																		),
																	),
																]
															),
														),
													),
												],
											)
										),
									),
								),
							),
						],
					),
				),
			),
		);
	}
}