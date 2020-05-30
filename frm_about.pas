unit frm_about;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, frm_aboutframe;

type
  TAboutForm = class(TForm)
    AboutFrame1: TAboutFrame;
    Panel1: TPanel;
    OKButton1: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.DFM}

end.
