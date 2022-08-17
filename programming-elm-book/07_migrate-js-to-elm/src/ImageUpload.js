/***
 * Excerpted from "Programming Elm",
 * published by The Pragmatic Bookshelf.
 * Copyrights apply to this code. It may not be used to create training material,
 * courses, books, articles, and the like. Contact us if you are in doubt.
 * We make no guarantees that this code is fit for any purpose.
 * Visit http://www.pragmaticprogrammer.com/titles/jfelm for more book information.
***/
import React, { Component } from 'react';
// webpack の設定によって elm ファイルも import できる
// 作成したアプリケーションを内包する Elm オブジェクトを受け取れる
import { Elm } from './ImageUpload.elm';
import './ImageUpload.css';

const IMAGE_UPLOADER_ID = 'file-upload';

class ImageUpload extends Component {
  constructor(props) {
    super(props);
    // React.ref とは実際のDOMノードに対する参照を保持したオブジェクト
    this.elmRef = React.createRef();
  }

  componentDidMount() {
    this.elm = Elm.ImageUpload.init({
      // Elm の画像アップロード機能を elmRef.current が保持する実際のDOMにElmアプリを初期化
      node: this.elmRef.current,
      flags: {
        imageUploaderId: IMAGE_UPLOADER_ID,
        images: this.props.images,
      }
    });

    // Elmからの外向きポートを購読する
    // 引数にはElmからデータを受け取ったときに呼ばれるコールバック関数を指定する
    this.elm.ports.uploadImages.subscribe(this.readImages);
  }

  componentDidUpdate(prevProps, prevState, snapshot) {
    // アップロードされて受け取った画像を Elm 側へ送信して表示させる
    this.elm.ports.receiveImages.send(this.props.images);
  }

  componentWillUnmount() {
    this.elm.ports.uploadImages.unsubscribe(this.readImages);
  }

  readImages = () => {
    const element = document.getElementById(IMAGE_UPLOADER_ID);
    // Elm は files プロパティを扱えないので、JS側でいじる必要がある
    const files = Array.from(element.files);

    Promise.all(files.map(this.readImage)).then(this.props.onUpload);
  }

  readImage = (file) => {
    const reader = new FileReader();
    const promise = new Promise((resolve) => {
      reader.onload = (e) => {
        resolve({
          url: e.target.result,
        });
      };
    });
    reader.readAsDataURL(file);
    return promise;
  }

  render() {
    // 仮想div にエルムアプリをマウント
    /*
     * render 内で ref に値を割り当てておくと、
     * render が出力した仮想 DOM を React が処理するときに、
     * 実際の DOM ノードが ref に渡される
     */
    return <div ref={this.elmRef} />;
  }
}

export default ImageUpload;
