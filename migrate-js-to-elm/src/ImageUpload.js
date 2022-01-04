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
    });
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
