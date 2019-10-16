//
//  ViewController.swift
//  LearnSignInWithApple
//
//  Created by 仲召俊 on 2019/10/16.
//  Copyright © 2019 仲召俊. All rights reserved.
//

import UIKit
import AuthenticationServices

class ViewController: UIViewController {

    lazy var appleIDInfLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 100, width: self.view.frame.width, height: self.view.frame.height*0.4))
        label.font = UIFont.systemFont(ofSize: 20)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = "显示Sign In With Apple登录信息\n"
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.addSubview(appleIDInfLabel)
        
        if #available(iOS 13.0, *) {
            //Sign In With Apple Button
            let appleIDBtn = ASAuthorizationAppleIDButton(authorizationButtonType: .default, authorizationButtonStyle: .white)
            appleIDBtn.frame = CGRect(x: 30, y: self.view.bounds.size.height - 180, width: self.view.bounds.size.width-60, height: 100)
            appleIDBtn.addTarget(self, action: #selector(appleIDBtnAction), for: .touchUpInside)
            view.addSubview(appleIDBtn)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performExisitingAccountSetupFlows()
    }
    
    //处理授权
    @objc
    func appleIDBtnAction() {
        if #available(iOS 13.0, *) {
            //基于用户的apple id授权用户，生成用户授权请求的一种机制
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            //创建新的apple id授权请求
            let appleIDRequest = appleIDProvider.createRequest()
            //在用户授权期间请求的联系联系
            appleIDRequest.requestedScopes = [ASAuthorization.Scope.fullName, ASAuthorization.Scope.email]
            //由ASAuthorizationAppleIDProvider创建的授权请求，管理授权请求的控制器
            let authorizationController = ASAuthorizationController(authorizationRequests: [appleIDRequest])
            //设置授权控制器通知授权请求的成功与失败的代理
            authorizationController.delegate = self
            //设置提供 展示上下文的代理，在这个上下文中，系统可以展示授权界面给用户
            authorizationController.presentationContextProvider = self
            //在控制器初始化期间启动授权流
            authorizationController.performRequests()
            
        }
    }
    
    //如果存在iCloud Keychain凭证或者appleid，凭证提示用户
    func performExisitingAccountSetupFlows() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let appleIDrequest = appleIDProvider.createRequest()
        let passwordProvider = ASAuthorizationPasswordProvider()
        let passwordrequest = passwordProvider.createRequest()
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [appleIDrequest, passwordrequest])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
        
    }
    
}

extension ViewController:ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("授权完成：\(authorization.credential)")
        print(controller)
        print(authorization)
        
        if authorization.credential.isKind(of: ASAuthorizationAppleIDCredential.classForCoder()) {
            //用户登录使用ASAuthorizationAppleIDCredential
            let appleIDCredential = authorization.credential as! ASAuthorizationAppleIDCredential
            let user = appleIDCredential.user
            let familyName = appleIDCredential.fullName?.familyName ?? ""
            let givenName = appleIDCredential.fullName?.givenName ?? ""
            let email = appleIDCredential.email ?? ""
            
            //需要使用钥匙串的方式保存用户的唯一信息
            do {
                try KeychainItem(service: "com.example.apple-samplecode.juice", account: "userIdentifier").saveItem(user)
            } catch {
                print("Unable to save userIdentifier to keychain.")
            }
            
            let mStr = appleIDInfLabel.text! + user + "\n" + familyName + "\n" + givenName + "\n" + email
            appleIDInfLabel.text = mStr
        } else if authorization.credential.isKind(of: ASPasswordCredential.classForCoder()) {
            //  用户登录使用现有的密码凭证
            let passwordCredential = authorization.credential as! ASPasswordCredential
            //  密码凭证对象的用户标识
            let user = passwordCredential.user
            //密码凭证对象的密码
            let password = passwordCredential.password
            
            let mStr = appleIDInfLabel.text! + user + "\n" + password + "\n"
            appleIDInfLabel.text = mStr
        } else {
            print("授权信息均不符")
            appleIDInfLabel.text = "授权信息均不符"
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Handle error: \(error.localizedDescription)")
        
        var errorMsg = ""
        switch error {
        case ASAuthorizationError.canceled:
            errorMsg = "用户取消了授权请求"
        case ASAuthorizationError.failed:
            errorMsg = "授权请求失败"
        case ASAuthorizationError.invalidResponse:
            errorMsg = "授权请求响应无效"
        case ASAuthorizationError.notHandled:
            errorMsg = "未能处理授权请求"
        case ASAuthorizationError.unknown:
            errorMsg = "授权请求失败未知原因"
        default:
            break
        }
        
        let mStr = appleIDInfLabel.text! + "\n" + errorMsg + "\n"
        appleIDInfLabel.text = mStr
    }
    
    //告诉代理应该在哪个window展示内容给用户
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
}
