/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (C) 2020, 2021 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:wger/helpers/consts.dart';
import 'package:wger/helpers/ui.dart';
import 'package:wger/models/http_exception.dart';

import '../providers/auth.dart';

enum AuthMode {
  Signup,
  Login,
}

class AuthScreen extends StatelessWidget {
  static const routeName = '/auth';

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Container(
              height: deviceSize.height,
              width: deviceSize.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(padding: EdgeInsets.symmetric(vertical: 20)),
                  Image(
                    image: AssetImage('assets/images/logo-white.png'),
                    width: 120,
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 20.0),
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 94.0),
                    child: Text(
                      'WGER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 50,
                        fontFamily: 'OpenSansBold',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Flexible(
                    //flex: deviceSize.width > 600 ? 2 : 1,
                    child: AuthCard(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthCard extends StatefulWidget {
  const AuthCard();

  @override
  _AuthCardState createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  AuthMode _authMode = AuthMode.Login;
  bool _hideCustomServer = true;
  Map<String, String> _authData = {
    'username': '',
    'email': '',
    'password': '',
    'serverUrl': '',
  };
  var _isLoading = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();
  final _emailController = TextEditingController();
  final _serverUrlController = TextEditingController(text: DEFAULT_SERVER);

  @override
  void initState() {
    //_serverUrlController.text
    super.initState();
    context.read<AuthProvider>().getServerUrlFromPrefs().then((value) {
      _serverUrlController.text = value;
    });
  }

  void _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      // Invalid!
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });
    try {
      // Login existing user
      if (_authMode == AuthMode.Login) {
        await Provider.of<AuthProvider>(context, listen: false).login(
          _authData['username']!,
          _authData['password']!,
          _authData['serverUrl']!,
        );

        // Register new user
      } else {
        await Provider.of<AuthProvider>(context, listen: false).register(
          username: _authData['username']!,
          password: _authData['password']!,
          email: _authData['email']!,
          serverUrl: _authData['serverUrl']!,
        );
      }

      setState(() {
        _isLoading = false;
      });
    } on WgerHttpException catch (error) {
      showHttpExceptionErrorDialog(error, context);
    } catch (error) {
      showErrorDialog(error, context);
    }
  }

  void _switchAuthMode() {
    if (_authMode == AuthMode.Login) {
      setState(() {
        _authMode = AuthMode.Signup;
      });
    } else {
      setState(() {
        _authMode = AuthMode.Login;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 8.0,
      child: Container(
        width: deviceSize.width * 0.75,
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: AutofillGroup(
              child: Column(
                children: <Widget>[
                  TextFormField(
                    key: Key('inputUsername'),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).username,
                      errorMaxLines: 2,
                    ),
                    autofillHints: [AutofillHints.username],
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (!RegExp(r'^[\w.@+-]+$').hasMatch(value!)) {
                        return AppLocalizations.of(context).usernameValidChars;
                      }
                      if (value.isEmpty) {
                        return AppLocalizations.of(context).invalidUsername;
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _authData['username'] = value!;
                    },
                  ),
                  if (_authMode == AuthMode.Signup)
                    TextFormField(
                      key: Key('inputEmail'),
                      decoration: InputDecoration(labelText: AppLocalizations.of(context).email),
                      autofillHints: [AutofillHints.email],
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,

                      // Email is not required
                      validator: (value) {
                        if (value!.isNotEmpty && !value.contains('@')) {
                          return AppLocalizations.of(context).invalidEmail;
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _authData['email'] = value!;
                      },
                    ),
                  TextFormField(
                    key: Key('inputPassword'),
                    decoration: InputDecoration(labelText: AppLocalizations.of(context).password),
                    autofillHints: [AutofillHints.password],
                    obscureText: true,
                    controller: _passwordController,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value!.isEmpty || value.length < 8) {
                        return AppLocalizations.of(context).passwordTooShort;
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _authData['password'] = value!;
                    },
                  ),
                  if (_authMode == AuthMode.Signup)
                    TextFormField(
                      key: Key('inputPassword2'),
                      decoration:
                          InputDecoration(labelText: AppLocalizations.of(context).confirmPassword),
                      controller: _password2Controller,
                      enabled: _authMode == AuthMode.Signup,
                      obscureText: true,
                      validator: _authMode == AuthMode.Signup
                          ? (value) {
                              if (value != _passwordController.text) {
                                return AppLocalizations.of(context).passwordsDontMatch;
                              }
                              return null;
                            }
                          : null,
                    ),
                  // Off-stage widgets are kept in the tree, otherwise the server URL
                  // would not be saved to _authData
                  Offstage(
                    offstage: _hideCustomServer,
                    child: Row(
                      children: [
                        Flexible(
                          flex: 3,
                          child: TextFormField(
                            key: Key('inputServer'),
                            decoration: InputDecoration(
                                labelText: AppLocalizations.of(context).customServerUrl,
                                helperText: AppLocalizations.of(context).customServerHint,
                                helperMaxLines: 4),
                            controller: _serverUrlController,
                            validator: (value) {
                              if (Uri.tryParse(value!) == null) {
                                return AppLocalizations.of(context).invalidUrl;
                              }

                              if (value.isEmpty || !value.contains('http')) {
                                return AppLocalizations.of(context).invalidUrl;
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _authData['serverUrl'] = value!;
                            },
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.undo),
                              onPressed: () {
                                _serverUrlController.text = DEFAULT_SERVER;
                              },
                            ),
                            Text(AppLocalizations.of(context).reset)
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  if (_isLoading)
                    CircularProgressIndicator()
                  else
                    ElevatedButton(
                      key: Key('actionButton'),
                      child: Text(_authMode == AuthMode.Login
                          ? AppLocalizations.of(context).login
                          : AppLocalizations.of(context).register),
                      onPressed: () {
                        return _submit(context);
                      },
                    ),
                  TextButton(
                    key: Key('toggleActionButton'),
                    child: Text(
                      _authMode == AuthMode.Login
                          ? AppLocalizations.of(context).registerInstead.toUpperCase()
                          : AppLocalizations.of(context).loginInstead.toUpperCase(),
                    ),
                    onPressed: _switchAuthMode,
                  ),
                  TextButton(
                    child: Text(_hideCustomServer
                        ? AppLocalizations.of(context).useCustomServer
                        : AppLocalizations.of(context).useDefaultServer),
                    key: Key('toggleCustomServerButton'),
                    onPressed: () {
                      setState(() {
                        _hideCustomServer = !_hideCustomServer;
                      });
                    },
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
