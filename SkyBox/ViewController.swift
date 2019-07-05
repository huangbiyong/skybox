//
//  ViewController.swift
//  SkyBox
//
//  Created by chhu02 on 2019/7/4.
//  Copyright © 2019 chase. All rights reserved.
//

import GLKit
import OpenGLES.ES2.glext

class ViewController: GLKViewController {

    let context = EAGLContext.init(api: .openGLES2)
    let baseEffect = GLKBaseEffect.init()
    let skyboxEffect = GLKSkyboxEffect.init()
    
    var eyePosition = GLKVector3Make(0.0, 0.0, 0.0)
    var lookAtPosition = GLKVector3Make(0.0, 0.0, 0.0)
    var upVector = GLKVector3Make(0.0, 1.0, 0.0)
    
    var angle: Float = 0.0
    var mPositionBuffer: GLuint?
    var mNormalBuffer: GLuint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // 1. 设置上下文
        setupContext()
        
        // 2. 设置飞机的GLKBaseEffect
        setupBaseEffect()
        
        // 3. 将顶点，纹理，法线数据从cpu 复制到 gpu
        setupBuffers()
        
        // 4. 开启深度测试和剔除   不然会绘制背部，和出现闪烁效果
        glEnable(GLenum(GL_CULL_FACE))
        glEnable(GLenum(GL_DEPTH_TEST))
        
        // 5. 加载天空盒子的天空纹理
        setupSkyBoxTexture()
        
        // 6. 设置视角
        setMatrices()
    }


}


// 设置opengl es 的环境
extension ViewController {
    
    func setupContext() {
        let view = self.view as! GLKView
        view.context = context!
        view.drawableColorFormat = .RGBA8888
        view.drawableDepthFormat = .format24
        EAGLContext.setCurrent(context!)
    }
    
    // 设置飞机的BaseEffect
    func setupBaseEffect() {
        baseEffect.light0.enabled = GLboolean(GL_TRUE)
        baseEffect.light0.position = GLKVector4Make(0.0, 0.0, 2.0, 1.0)
        baseEffect.light0.specularColor = GLKVector4Make(0.25, 0.25, 0.25, 1.0)
        baseEffect.light0.diffuseColor = GLKVector4Make(0.75, 0.75, 0.75, 1.0)
        baseEffect.lightingType = .perPixel
    }
    
    // 设置缓存，将数据从cpu 复制到 gpu
    func setupBuffers() {
        
        // 1. 设置顶点缓存
        var buffer:GLuint = 0
        glGenBuffers(1, &buffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), buffer)
        
        var starshipPositions1 = starshipPositions
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout.size(ofValue: starshipPositions1), &starshipPositions1 , GLenum(GL_STATIC_DRAW))
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue)) // 设置顶点可见
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.stride*0), nil) // 设置顶点数据的读取方式
        
        mPositionBuffer = buffer

        
        // 2. 设置法线缓存
        glGenBuffers(1, &buffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), buffer)
        
        starshipPositions1 = starshipNormals
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout.size(ofValue: starshipPositions1), &starshipPositions1 , GLenum(GL_STATIC_DRAW))
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.normal.rawValue)) // 设置法线可见
        glVertexAttribPointer(GLuint(GLKVertexAttrib.normal.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.stride*0), nil) // 设置发现数据的读取方式
        
        mNormalBuffer = buffer
       
    }
    
    // 加载天空盒子的纹理
    func setupSkyBoxTexture() {
        
        let path = Bundle.main.path(forResource: "image", ofType: "png")!
        let url = URL.init(fileURLWithPath: path)
        
        let textureInfo = try? GLKTextureLoader.cubeMap(withContentsOf: url, options: nil)
        
        guard let textureI = textureInfo  else {
            return
        }
        
        skyboxEffect.textureCubeMap.name = textureI.name
        skyboxEffect.textureCubeMap.target = GLKTextureTarget(rawValue: textureI.target)!
        
    }
    
    func setMatrices() {
        let aspectRatio: GLfloat = GLfloat(self.view.bounds.width / self.view.bounds.height)
        baseEffect.transform.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85.0), aspectRatio, 0.2, 23.0)
        
        baseEffect.transform.modelviewMatrix = GLKMatrix4MakeLookAt(eyePosition.x, eyePosition.y, eyePosition.z, lookAtPosition.x, lookAtPosition.y, lookAtPosition.z, upVector.x, upVector.y, upVector.z)
        
        skyboxEffect.center = self.eyePosition
        skyboxEffect.transform.projectionMatrix = baseEffect.transform.projectionMatrix
        skyboxEffect.transform.modelviewMatrix = baseEffect.transform.modelviewMatrix
        

        angle += 0.01
        
        eyePosition = GLKVector3Make(-5.0 * sin(angle), -5.0, -5.0 * cos(angle))  // 眼睛位置
        lookAtPosition = GLKVector3Make(0.0 , 1.5 + -5.0 * sin(0.3 * angle), 0.0) // 观察的位置， 为了效果更好上下浮动
    }
    
}

extension ViewController {
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClearColor(0.5, 0.1, 0.1, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        
        // 1. 改变视角
        setMatrices()
        
        // 2. 绘制天空盒子
        skyboxEffect.prepareToDraw()
        glDepthMask(GLboolean(GL_FALSE))
        skyboxEffect.draw()
        glDepthMask(GLboolean(GL_TRUE))
        
        
        //glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), 0)
        //glBindTexture(GLenum(GL_TEXTURE_CUBE_MAP), 0)

        // 3. 读取飞机模型数据
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), mPositionBuffer!);
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue));
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, nil);
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), mNormalBuffer!);
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.normal.rawValue));
        glVertexAttribPointer(GLuint(GLKVertexAttrib.normal.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, nil);
    
        
        // 转换数据     将元组变为数组
        let diffusesM = Mirror(reflecting: starshipDiffuses)
        let specularsM = Mirror(reflecting: starshipSpeculars)
        let firstsM = Mirror(reflecting: starshipFirsts)
        let countsM = Mirror(reflecting: starshipCounts)
        
    
        var diffusesArr:[ (GLfloat, GLfloat, GLfloat)] = []
        var specularsArr:[ (GLfloat, GLfloat, GLfloat)] = []
        var firstsArr:[ GLint] = []
        var countsArr:[ GLint] = []
        
        
        for diffuses in diffusesM.children {
            let value = diffuses.value as! (GLfloat, GLfloat, GLfloat)
            diffusesArr.append(value)
        }

        for speculars in specularsM.children {
            let value = speculars.value as! (GLfloat, GLfloat, GLfloat)
            specularsArr.append(value)
        }

        for firsts in firstsM.children {
            let value = firsts.value as! (GLint)
            firstsArr.append(value)
        }
        
        for counts in countsM.children {
            let value = counts.value as! (GLint)
            countsArr.append(value)
        }
   
        
        // 4. 绘制飞机   需要绘制不同的颜色，所以需要for循环
        for i in 0..<diffusesArr.count {

            let diffusesValue = diffusesArr[i]
            let specularsValue = specularsArr[i]
            let firstValue = firstsArr[i]
            let countValue = countsArr[i]

            self.baseEffect.material.diffuseColor = GLKVector4Make(diffusesValue.0, diffusesValue.1, diffusesValue.2, 1.0);
            self.baseEffect.material.specularColor = GLKVector4Make(specularsValue.0, specularsValue.1, specularsValue.2, 1.0);
            baseEffect.prepareToDraw()
            glDrawArrays(GLenum(GL_TRIANGLES), firstValue, countValue);
        }
        
        // 如果不想使用多种颜色的飞机，可以这样写，比较简洁
//        baseEffect.prepareToDraw()
//        glDrawArrays(GLenum(GL_TRIANGLES), 0, 30+33+3); // 30+33+3 == starshipCounts

        
    }
}

