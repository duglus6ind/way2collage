import 'package:flutter/material.dart';
class UserLogin extends StatefulWidget {
	const UserLogin({super.key});
	@override
		UserLoginState createState() => UserLoginState();
	}
class UserLoginState extends State<UserLogin> {
	String textField1 = '';
	String textField2 = '';
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
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													IntrinsicHeight(
														child: Container(
															margin: const EdgeInsets.only( bottom: 6),
															width: double.infinity,
															child: Row(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	IntrinsicWidth(
																		child: IntrinsicHeight(
																			child: Container(
																				margin: const EdgeInsets.only( right: 21),
																				child: Stack(
																					clipBehavior: Clip.none,
																					children: [
																						Column(
																							crossAxisAlignment: CrossAxisAlignment.start,
																							children: [
																								Container(
																									width: 150,
																									height: 150,
																									child: Image.network(
																										"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/Y8FDqv2vvv/grecp1b1_expires_30_days.png",
																										fit: BoxFit.fill,
																									)
																								),
																							]
																						),
																						Positioned(
																							bottom: 0,
																							right: 20,
																							width: 60,
																							height: 60,
																							child: Container(
																								transform: Matrix4.translationValues(0, 45, 0),
																								width: 60,
																								height: 60,
																								child: Image.network(
																									"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/Y8FDqv2vvv/b3gq0lvi_expires_30_days.png",
																									fit: BoxFit.fill,
																								)
																							),
																						),
																					]
																				),
																			),
																		),
																	),
																	Expanded(
																		child: IntrinsicHeight(
																			child: Container(
																				width: double.infinity,
																				child: Column(
																					children: [
																						IntrinsicHeight(
																							child: Container(
																								width: double.infinity,
																								child: Row(
																									crossAxisAlignment: CrossAxisAlignment.start,
																									children: [
																										IntrinsicWidth(
																											child: IntrinsicHeight(
																												child: Container(
																													margin: const EdgeInsets.only( right: 18),
																													child: Column(
																														crossAxisAlignment: CrossAxisAlignment.start,
																														children: [
																															Container(
																																margin: const EdgeInsets.only( bottom: 15, left: 26),
																																width: 60,
																																height: 60,
																																child: Image.network(
																																	"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/Y8FDqv2vvv/c6eky4cv_expires_30_days.png",
																																	fit: BoxFit.fill,
																																)
																															),
																															Container(
																																width: 60,
																																height: 60,
																																child: Image.network(
																																	"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/Y8FDqv2vvv/8kvq80aw_expires_30_days.png",
																																	fit: BoxFit.fill,
																																)
																															),
																														]
																													),
																												),
																											),
																										),
																										Expanded(
																											child: Container(
																												height: 150,
																												width: double.infinity,
																												child: Image.network(
																													"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/Y8FDqv2vvv/tlshliih_expires_30_days.png",
																													fit: BoxFit.fill,
																												)
																											),
																										),
																									]
																								),
																							),
																						),
																						Container(
																							width: 60,
																							height: 60,
																							child: Image.network(
																								"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/Y8FDqv2vvv/1wrzmtu9_expires_30_days.png",
																								fit: BoxFit.fill,
																							)
																						),
																					]
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
															decoration: BoxDecoration(
																borderRadius: BorderRadius.circular(46),
																color: Color(0xFF32767F),
															),
															margin: const EdgeInsets.symmetric(horizontal: 22),
															width: double.infinity,
															child: Column(
																children: [
																	IntrinsicHeight(
																		child: Container(
																			alignment: Alignment.center,
																			decoration: BoxDecoration(
																				borderRadius: BorderRadius.circular(10),
																				color: Color(0xFFFFFFFF),
																			),
																			margin: const EdgeInsets.only( top: 122, bottom: 30, left: 40, right: 40),
																			width: double.infinity,
																			child: TextField(
																				style: TextStyle(
																					color: Color(0xFF000000),
																					fontSize: 16,
																				),
																				onChanged: (value) { 
																					setState(() { textField1 = value; });
																				},
																				decoration: InputDecoration(
																					hintText: "User Name",
																					isDense: true,
																					contentPadding: const EdgeInsets.only( top: 10, bottom: 10, left: 21, right: 21),
																					border: InputBorder.none,
																					focusedBorder: InputBorder.none,
																					filled: false,
																				),
																			),
																		),
																	),
																	IntrinsicHeight(
																		child: Container(
																			alignment: Alignment.center,
																			decoration: BoxDecoration(
																				borderRadius: BorderRadius.circular(10),
																				color: Color(0xFFFFFFFF),
																			),
																			margin: const EdgeInsets.only( bottom: 55, left: 40, right: 40),
																			width: double.infinity,
																			child: TextField(
																				style: TextStyle(
																					color: Color(0xFF000000),
																					fontSize: 16,
																				),
																				onChanged: (value) { 
																					setState(() { textField2 = value; });
																				},
																				decoration: InputDecoration(
																					hintText: "Password",
																					isDense: true,
																					contentPadding: const EdgeInsets.only( top: 7, bottom: 7, left: 21, right: 21),
																					border: InputBorder.none,
																					focusedBorder: InputBorder.none,
																					filled: false,
																				),
																			),
																		),
																	),
																	InkWell(
																		onTap: () { print('Pressed'); },
																		child: IntrinsicWidth(
																			child: IntrinsicHeight(
																				child: Container(
																					decoration: BoxDecoration(
																						borderRadius: BorderRadius.circular(31),
																						color: Color(0xFFFFFFFF),
																					),
																					padding: const EdgeInsets.only( top: 16, bottom: 16, left: 67, right: 67),
																					margin: const EdgeInsets.only( bottom: 74),
																					child: Column(
																						crossAxisAlignment: CrossAxisAlignment.start,
																						children: [
																							Text(
																								"Login",
																								style: TextStyle(
																									color: Color(0xFF000000),
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
													IntrinsicWidth(
														child: IntrinsicHeight(
															child: Container(
																margin: const EdgeInsets.only( bottom: 6),
																child: Row(
																	crossAxisAlignment: CrossAxisAlignment.start,
																	children: [
																		IntrinsicWidth(
																			child: IntrinsicHeight(
																				child: Container(
																					margin: const EdgeInsets.only( right: 70),
																					child: Stack(
																						clipBehavior: Clip.none,
																						children: [
																							Column(
																								crossAxisAlignment: CrossAxisAlignment.start,
																								children: [
																									Container(
																										width: 150,
																										height: 150,
																										child: Image.network(
																											"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/Y8FDqv2vvv/whlntzbn_expires_30_days.png",
																											fit: BoxFit.fill,
																										)
																									),
																								]
																							),
																							Positioned(
																								bottom: 8,
																								right: 0,
																								width: 60,
																								height: 60,
																								child: Container(
																									transform: Matrix4.translationValues(17, 0, 0),
																									width: 60,
																									height: 60,
																									child: Image.network(
																										"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/Y8FDqv2vvv/5xwvjqig_expires_30_days.png",
																										fit: BoxFit.fill,
																									)
																								),
																							),
																						]
																					),
																				),
																			),
																		),
																		Container(
																			margin: const EdgeInsets.only( top: 22),
																			width: 60,
																			height: 60,
																			child: Image.network(
																				"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/Y8FDqv2vvv/gnkq5is6_expires_30_days.png",
																				fit: BoxFit.fill,
																			)
																		),
																	]
																),
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( left: 100),
														width: 150,
														height: 60,
														child: Image.network(
															"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/Y8FDqv2vvv/3u6rh9vi_expires_30_days.png",
															fit: BoxFit.fill,
														)
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